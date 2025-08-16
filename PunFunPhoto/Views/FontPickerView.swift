import SwiftUI

struct FontPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFont: FontInfo?
    @StateObject private var fontManager = FontManager.shared
    
    @State private var searchText = ""
    @State private var showingManagement = false
    @State private var selectedCategory: FontCategory?
    @State private var showOfflineAlert = false
    
    // 임시 폰트 목록 (실제로는 서버에서 받아와야 함)
    private let availableFonts = [
        FontInfo(id: "nanum-gothic",
                name: "NanumGothic",
                displayName: "나눔고딕",
                downloadUrl: "https://example.com/fonts/NanumGothic.ttf",
                previewUrl: "https://example.com/fonts/preview/NanumGothic",
                fileSize: 1024 * 1024,
                category: .gothic,
                lastUsedDate: nil),
        // 더 많은 폰트 추가
    ]
    
    private var categories: [FontCategory] {
        var categories = Set(availableFonts.map { $0.category })
        categories.insert(.system)
        return categories.sorted { $0.rawValue < $1.rawValue }
    }
    
    private var filteredFonts: [FontInfo] {
        var fonts = availableFonts
        
        // 카테고리 필터링
        if let category = selectedCategory {
            fonts = fonts.filter { $0.category == category }
        }
        
        // 검색어 필터링
        if !searchText.isEmpty {
            fonts = fonts.filter { font in
                font.displayName.localizedCaseInsensitiveContains(searchText) ||
                font.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return fonts
    }
    
    var body: some View {
        NavigationView {
            List {
                if fontManager.isOffline {
                    Section {
                        HStack {
                            Image(systemName: "wifi.slash")
                            Text("오프라인 모드")
                            Spacer()
                            Text("다운로드된 폰트만 사용 가능")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                if !fontManager.recentlyUsedFonts.isEmpty {
                    Section(header: Text("최근 사용한 폰트")) {
                        ForEach(fontManager.recentlyUsedFonts) { font in
                            FontRowView(
                                font: font,
                                isSelected: selectedFont?.id == font.id,
                                isDownloaded: fontManager.isDownloaded(font.name)
                            ) {
                                selectFont(font)
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        selectedFont = nil
                        dismiss()
                    }) {
                        HStack {
                            Text("시스템 폰트")
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedFont == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(categories, id: \.self) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    if selectedCategory == category {
                                        selectedCategory = nil
                                    } else {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .listRowInsets(EdgeInsets())
                    
                    ForEach(filteredFonts) { font in
                        FontRowView(
                            font: font,
                            isSelected: selectedFont?.id == font.id,
                            isDownloaded: fontManager.isDownloaded(font.name)
                        ) {
                            selectFont(font)
                        }
                    }
                } header: {
                    Text("다운로드 가능한 폰트")
                }
            }
            .searchable(text: $searchText, prompt: "폰트 검색")
            .navigationTitle("폰트 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingManagement = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingManagement) {
                NavigationView {
                    FontManagementView()
                }
            }
            .alert("오프라인 모드", isPresented: $showOfflineAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("인터넷 연결이 필요합니다. 네트워크 연결을 확인해주세요.")
            }
        }
    }
    
    private func selectFont(_ font: FontInfo) {
        if !fontManager.isDownloaded(font.name) && fontManager.isOffline {
            showOfflineAlert = true
            return
        }
        
        selectedFont = font
        fontManager.addToRecentlyUsed(font)
        dismiss()
    }
}

struct CategoryButton: View {
    let category: FontCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct FontRowView: View {
    let font: FontInfo
    let isSelected: Bool
    let isDownloaded: Bool
    let onSelect: () -> Void
    
    @StateObject private var fontManager = FontManager.shared
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading) {
                    Text(font.displayName)
                        .foregroundColor(.primary)
                    HStack {
                        Text("가나다라마바사 ABC 123")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let lastUsed = font.lastUsedDate {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(lastUsed, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    if isDownloaded {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .overlay {
            if let progress = fontManager.downloadProgress[font.name] {
                Color.black.opacity(0.1)
                ProgressView(value: progress) {
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                }
                .progressViewStyle(.linear)
                .padding()
            }
        }
    }
}

struct FontManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var fontManager = FontManager.shared
    @State private var showingDeleteAlert = false
    @State private var fontToDelete: FontInfo?
    @State private var showingClearCacheAlert = false
    
    var body: some View {
        List {
            Section(header: Text("다운로드된 폰트")) {
                if fontManager.downloadedFonts.isEmpty {
                    Text("다운로드된 폰트가 없습니다")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(fontManager.downloadedFonts) { font in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(font.displayName)
                                HStack {
                                    Text(font.category.displayName)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                    
                                    if let lastUsed = font.lastUsedDate {
                                        Text("마지막 사용: \(lastUsed, style: .relative)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                fontToDelete = font
                                showingDeleteAlert = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("저장 공간")) {
                HStack {
                    Text("사용 중인 용량")
                    Spacer()
                    Text(calculateTotalSize())
                }
                
                HStack {
                    Text("폰트 개수")
                    Spacer()
                    Text("\(fontManager.downloadedFonts.count)개")
                }
                
                Button(action: { showingClearCacheAlert = true }) {
                    HStack {
                        Text("캐시 지우기")
                        Spacer()
                        Text("프리뷰 이미지만 삭제")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("폰트 관리")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("완료") {
                    dismiss()
                }
            }
        }
        .alert("폰트 삭제", isPresented: $showingDeleteAlert, presenting: fontToDelete) { font in
            Button("삭제", role: .destructive) {
                deleteFont(font)
            }
            Button("취소", role: .cancel) {}
        } message: { font in
            Text("\(font.displayName) 폰트를 삭제하시겠습니까?")
        }
        .alert("캐시 지우기", isPresented: $showingClearCacheAlert) {
            Button("지우기", role: .destructive) {
                fontManager.clearCache()
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("프리뷰 이미지 캐시를 지우시겠습니까?\n폰트 파일은 유지됩니다.")
        }
    }
    
    private func calculateTotalSize() -> String {
        let size = fontManager.downloadedFonts.reduce(0) { $0 + $1.fileSize }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private func deleteFont(_ font: FontInfo) {
        do {
            try fontManager.deleteFont(font)
        } catch {
            print("폰트 삭제 실패: \(error.localizedDescription)")
        }
    }
}

#Preview {
    FontPickerView(selectedFont: .constant(nil))
} 