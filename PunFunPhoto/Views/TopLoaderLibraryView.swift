import SwiftUI

struct TopLoaderLibraryView: View {
    @Binding var isPresented: Bool
    let onSelect: (SavedTopLoader) -> Void
    
    @State private var savedTopLoaders: [SavedTopLoader] = []
    @State private var showNameInput = false
    @State private var newTopLoaderName = ""
    @State private var currentTopLoader: TopLoaderState?
    
    var body: some View {
        NavigationView {
            TopLoaderListContent(
                savedTopLoaders: $savedTopLoaders,
                isPresented: $isPresented,
                onSelect: onSelect,
                onNewTopLoader: createNewTopLoader
            )
            .navigationTitle("탑로더 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        isPresented = false
                    }
                }
            }
        }
        .alert("탑로더 이름", isPresented: $showNameInput) {
            SaveTopLoaderAlert(
                newTopLoaderName: $newTopLoaderName,
                showNameInput: $showNameInput,
                currentTopLoader: $currentTopLoader,
                onSave: handleSaveTopLoader
            )
        }
        .onAppear {
            loadSavedTopLoaders()
        }
    }
    
    private func createNewTopLoader() {
        let newLoader = TopLoaderState()
        newLoader.attach()
        currentTopLoader = newLoader
        showNameInput = true
    }
    
    private func handleSaveTopLoader() {
        guard let loader = currentTopLoader else { return }
        let savedLoader = SavedTopLoader(
            name: newTopLoaderName.isEmpty ? "Untitled" : newTopLoaderName,
            stickers: loader.stickers,
            texts: loader.texts
        )
        savedTopLoaders.append(savedLoader)
        saveToPersistentStorage()
        loader.attach()
        onSelect(savedLoader)
        isPresented = false
        newTopLoaderName = ""
    }
    
    private func deleteTopLoader(at offsets: IndexSet) {
        savedTopLoaders.remove(atOffsets: offsets)
        saveToPersistentStorage()
    }
    
    private func loadSavedTopLoaders() {
        if let data = UserDefaults.standard.data(forKey: "SavedTopLoaders"),
           let decodedLoaders = try? JSONDecoder().decode([SavedTopLoader].self, from: data) {
            self.savedTopLoaders = decodedLoaders
        }
    }
    
    private func saveToPersistentStorage() {
        if let encoded = try? JSONEncoder().encode(savedTopLoaders) {
            UserDefaults.standard.set(encoded, forKey: "SavedTopLoaders")
        }
    }
}

struct TopLoaderListContent: View {
    @Binding var savedTopLoaders: [SavedTopLoader]
    @Binding var isPresented: Bool
    let onSelect: (SavedTopLoader) -> Void
    let onNewTopLoader: () -> Void
    
    var body: some View {
        List {
            Section(header: Text("새 탑로더")) {
                Button(action: onNewTopLoader) {
                    Label("빈 탑로더 만들기", systemImage: "plus.square")
                }
            }
            
            Section(header: Text("저장된 탑로더")) {
                if savedTopLoaders.isEmpty {
                    Text("저장된 탑로더가 없습니다")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(savedTopLoaders.sorted(by: { $0.createdAt > $1.createdAt })) { loader in
                        TopLoaderRow(loader: loader) {
                            onSelect(loader)
                            isPresented = false
                        }
                    }
                    .onDelete { offsets in
                        savedTopLoaders.remove(atOffsets: offsets)
                    }
                }
            }
        }
    }
}

struct TopLoaderRow: View {
    let loader: SavedTopLoader
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loader.name)
                        .font(.headline)
                    Text(loader.createdAt.formatted())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SaveTopLoaderAlert: View {
    @Binding var newTopLoaderName: String
    @Binding var showNameInput: Bool
    @Binding var currentTopLoader: TopLoaderState?
    let onSave: () -> Void
    
    var body: some View {
        TextField("이름을 입력하세요", text: $newTopLoaderName)
        Button("취소", role: .cancel) {
            showNameInput = false
            currentTopLoader = nil
            newTopLoaderName = ""
        }
        Button("저장") {
            onSave()
        }
    }
}

#Preview {
    TopLoaderLibraryView(isPresented: .constant(true)) { _ in }
} 