import SwiftUI
import CoreText
import Network

class FontManager: ObservableObject {
    static let shared = FontManager()
    
    @Published var downloadedFonts: [FontInfo] = []
    @Published var downloadProgress: [String: Double] = [:]
    @Published var isOffline = false
    @Published var recentlyUsedFonts: [FontInfo] = []
    
    private var downloadTasks: [String: Task<Void, Error>] = [:]
    private var networkMonitor: NWPathMonitor?
    private let maxRecentFonts = 5
    private let imageCache = NSCache<NSString, UIImage>()
    
    private init() {
        loadDownloadedFonts()
        loadRecentlyUsedFonts()
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOffline = path.status != .satisfied
            }
        }
        networkMonitor?.start(queue: DispatchQueue.global())
    }
    
    private func loadDownloadedFonts() {
        if let data = UserDefaults.standard.data(forKey: "downloadedFonts"),
           let fonts = try? JSONDecoder().decode([FontInfo].self, from: data) {
            downloadedFonts = fonts
        }
    }
    
    private func loadRecentlyUsedFonts() {
        if let data = UserDefaults.standard.data(forKey: "recentlyUsedFonts"),
           let fonts = try? JSONDecoder().decode([FontInfo].self, from: data) {
            recentlyUsedFonts = fonts
        }
    }
    
    private func saveDownloadedFonts() {
        if let data = try? JSONEncoder().encode(downloadedFonts) {
            UserDefaults.standard.set(data, forKey: "downloadedFonts")
        }
    }
    
    private func saveRecentlyUsedFonts() {
        if let data = try? JSONEncoder().encode(recentlyUsedFonts) {
            UserDefaults.standard.set(data, forKey: "recentlyUsedFonts")
        }
    }
    
    func addToRecentlyUsed(_ font: FontInfo) {
        var updatedFont = font
        updatedFont.lastUsedDate = Date()
        
        recentlyUsedFonts.removeAll { $0.id == font.id }
        recentlyUsedFonts.insert(updatedFont, at: 0)
        
        if recentlyUsedFonts.count > maxRecentFonts {
            recentlyUsedFonts.removeLast()
        }
        
        saveRecentlyUsedFonts()
    }
    
    func isDownloaded(_ fontName: String) -> Bool {
        downloadedFonts.contains { $0.name == fontName }
    }
    
    func downloadFont(_ fontInfo: FontInfo) async throws {
        if isOffline {
            throw FontError.networkError
        }
        
        if isDownloaded(fontInfo.name) { return }
        
        if let existingTask = downloadTasks[fontInfo.name] {
            try await existingTask.value
            return
        }
        
        let task = Task {
            do {
                _ = await MainActor.run {
                    downloadProgress[fontInfo.name] = 0.0
                }
                
                let fontData = try await downloadFontFile(fontInfo)
                try saveFontFile(fontData, fontInfo: fontInfo)
                try registerFont(fontInfo)
                
                // 프리뷰 이미지 캐싱
                if let previewImage = try? await downloadPreviewImage(fontInfo) {
                    cachePreviewImage(previewImage, for: fontInfo)
                }
                
                _ = await MainActor.run {
                    downloadedFonts.append(fontInfo)
                    downloadProgress.removeValue(forKey: fontInfo.name)
                    saveDownloadedFonts()
                }
            } catch {
                _ = await MainActor.run {
                    downloadProgress.removeValue(forKey: fontInfo.name)
                }
                throw error
            }
        }
        
        downloadTasks[fontInfo.name] = task
        try await task.value
        downloadTasks.removeValue(forKey: fontInfo.name)
    }
    
    private func downloadFontFile(_ fontInfo: FontInfo) async throws -> Data {
        guard let url = URL(string: fontInfo.downloadUrl) else {
            throw FontError.invalidUrl
        }
        
        let (bytes, response) = try await URLSession.shared.bytes(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FontError.downloadFailed
        }
        
        let totalBytes = Int64(httpResponse.expectedContentLength)
        var downloadedData = Data()
        downloadedData.reserveCapacity(Int(totalBytes))
        
        var downloadedBytes: Int64 = 0
        for try await byte in bytes {
            downloadedData.append(byte)
            downloadedBytes += 1
            
            let progress = Double(downloadedBytes) / Double(totalBytes)
            _ = await MainActor.run {
                downloadProgress[fontInfo.name] = progress
            }
        }
        
        return downloadedData
    }
    
    private func downloadPreviewImage(_ fontInfo: FontInfo) async throws -> UIImage {
        guard let url = URL(string: fontInfo.previewUrl) else {
            throw FontError.invalidUrl
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let image = UIImage(data: data) else {
            throw FontError.downloadFailed
        }
        
        return image
    }
    
    private func cachePreviewImage(_ image: UIImage, for fontInfo: FontInfo) {
        imageCache.setObject(image, forKey: fontInfo.id as NSString)
    }
    
    func getPreviewImage(for fontInfo: FontInfo) -> UIImage? {
        return imageCache.object(forKey: fontInfo.id as NSString)
    }
    
    private func saveFontFile(_ data: Data, fontInfo: FontInfo) throws {
        guard let fontDirectory = getFontDirectory() else {
            throw FontError.saveFailed
        }
        
        try FileManager.default.createDirectory(at: fontDirectory, withIntermediateDirectories: true)
        
        let fontUrl = fontDirectory.appendingPathComponent("\(fontInfo.name).ttf")
        try data.write(to: fontUrl)
    }
    
    private func registerFont(_ fontInfo: FontInfo) throws {
        guard let fontDirectory = getFontDirectory() else {
            throw FontError.registrationFailed
        }
        let fontUrl = fontDirectory.appendingPathComponent("\(fontInfo.name).ttf")
        var error: Unmanaged<CFError>?
        let success = CTFontManagerRegisterFontsForURL(fontUrl as CFURL, .process, &error)
        if !success {
            throw FontError.registrationFailed
        }
    }
    
    private func getFontDirectory() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Fonts")
    }
    
    func deleteFont(_ fontInfo: FontInfo) throws {
        guard let fontDirectory = getFontDirectory() else {
            throw FontError.deleteFailed
        }
        
        let fontUrl = fontDirectory.appendingPathComponent("\(fontInfo.name).ttf")
        try FileManager.default.removeItem(at: fontUrl)
        
        downloadedFonts.removeAll { $0.id == fontInfo.id }
        recentlyUsedFonts.removeAll { $0.id == fontInfo.id }
        imageCache.removeObject(forKey: fontInfo.id as NSString)
        
        saveDownloadedFonts()
        saveRecentlyUsedFonts()
    }
    
    func clearCache() {
        imageCache.removeAllObjects()
    }
    
    deinit {
        networkMonitor?.cancel()
    }
} 
