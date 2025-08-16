import SwiftUI
//import ZipArchive

struct SavedProjectListView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    @ObservedObject var photo1: PhotoState
    @ObservedObject var photo2: PhotoState

    // MARK: - States
    @State private var savedProjects: [URL] = []
    @State private var filteredProjects: [URL] = []
    @State private var searchText: String = ""
    @State private var shareURL: URL? = nil
    @State private var showShareSheet = false
    @State private var isEditing = false
    @State private var selectedURLs: Set<URL> = []
    @State private var showAlert = false
    @State private var alertMessage = ""

    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack {
                searchField

                List {
                    ForEach(filteredProjects, id: \.path) { url in
                        fileRow(for: url)
                    }

                    if isEditing && !selectedURLs.isEmpty {
                        deleteSelectedButton
                    }
                }
            }
            .navigationTitle("저장된 포토카드")
            .toolbar { editButton }
            .onAppear(perform: refreshProjectList)
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertMessage))
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    // MARK: - Subviews

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("파일명 검색", text: $searchText)
                .onChange(of: searchText) {
                    applySearchFilter()
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    applySearchFilter()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private func fileRow(for url: URL) -> some View {
        HStack {
            if isEditing {
                Button(action: { toggleSelection(for: url) }) {
                    Image(systemName: selectedURLs.contains(url) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(.blue)
                }
            }

            Button(action: {
                if !isEditing {
                    loadProject(from: url)
                }
            }) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(url.lastPathComponent)
                        .font(.body)
                    if let date = extractDate(from: url) {
                        Text(date)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    Text(fileSizeString(for: url))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button { share(url) } label: {
                Label("공유", systemImage: "square.and.arrow.up")
            }
            .tint(.blue)

            Button(role: .destructive) { deleteProject(at: url) } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }

    private var deleteSelectedButton: some View {
        Button("선택 항목 삭제") {
            deleteSelectedProjects()
        }
        .foregroundColor(.red)
    }

    private var editButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(isEditing ? "완료" : "선택") {
                isEditing.toggle()
                if !isEditing {
                    selectedURLs.removeAll()
                }
            }
        }
    }

    // MARK: - Logic

    private func refreshProjectList() {
        let allFiles = listSavedProjects()
        savedProjects = allFiles.filter { $0.pathExtension == "pfp" }
        applySearchFilter()
    }

    private func applySearchFilter() {
        if searchText.isEmpty {
            filteredProjects = savedProjects
        } else {
            filteredProjects = savedProjects.filter {
                $0.lastPathComponent.lowercased().contains(searchText.lowercased())
            }
        }
    }

    private func loadProject(from url: URL) {
        loadProjectFromArchive(from: url, photo1: photo1, photo2: photo2)
        appState.currentProjectURL = url
        isPresented = false
    }

    private func toggleSelection(for url: URL) {
        if selectedURLs.contains(url) {
            selectedURLs.remove(url)
        } else {
            selectedURLs.insert(url)
        }
    }

    private func deleteProject(at url: URL) {
        try? FileManager.default.removeItem(at: url)
        refreshProjectList()
    }

    private func deleteSelectedProjects() {
        for url in selectedURLs {
            try? FileManager.default.removeItem(at: url)
        }
        refreshProjectList()
        selectedURLs.removeAll()
        isEditing = false
    }

    private func share(_ url: URL) {
        shareURL = url
        showShareSheet = true
    }

    private func extractDate(from url: URL) -> String? {
        let name = url.deletingPathExtension().lastPathComponent
        let formatter = DateFormatter()
        formatter.dateFormat = "'pfoca'_yyyyMMdd_HHmm"
        if let date = formatter.date(from: name) {
            let display = DateFormatter()
            display.dateFormat = "yyyy년 M월 d일 (HH:mm)"
            return display.string(from: date)
        }
        return nil
    }

    private func fileSizeString(for url: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? NSNumber {
                let sizeInMB = Double(truncating: fileSize) / 1024 / 1024
                return String(format: "%.1f MB", sizeInMB)
            }
        } catch {
            print("❌ 파일 크기 가져오기 실패:", error)
        }
        return "-"
    }
}
