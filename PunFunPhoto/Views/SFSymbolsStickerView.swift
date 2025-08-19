import SwiftUI

struct SFSymbolsStickerView: View {
    @Binding var isPresented: Bool
    let onSymbolSelected: (String) -> Void
    
    // 인기 있는 SF Symbols 카테고리
    private let categories = [
        ("기본", ["heart", "star", "checkmark", "xmark", "plus", "minus", "arrow.up", "arrow.down", "arrow.left", "arrow.right"]),
        ("감정", ["face.smiling", "heart.fill", "star.fill", "hand.thumbsup", "hand.thumbsdown", "hand.raised", "hand.wave"]),
        ("자연", ["leaf", "tree", "sun.max", "moon", "cloud", "rain", "snowflake", "flame", "drop"]),
        ("동물", ["pawprint", "bird", "fish", "ant", "ladybug", "tortoise", "hare"]),
        ("음식", ["applelogo", "carrot", "birthday.cake", "cup.and.saucer", "wineglass", "fork.knife"]),
        ("스포츠", ["sportscourt", "basketball", "football", "baseball", "tennis.racket", "volleyball"]),
        ("음악", ["music.note", "music.mic", "music.quarternote.3", "guitars", "pianokeys", "speaker.wave.3"]),
        ("교통", ["car", "airplane", "bus", "tram", "bicycle", "scooter", "boat"]),
        ("기술", ["laptopcomputer", "iphone", "ipad", "airpods", "gamecontroller", "tv", "camera"]),
        ("활동", ["figure.walk", "figure.run", "figure.dance", "figure.skiing", "figure.snowboarding", "figure.surfing"])
    ]
    
    @State private var selectedCategory = 0
    @State private var searchText = ""
    
    var filteredSymbols: [String] {
        let allSymbols = categories.flatMap { $0.1 }
        if searchText.isEmpty {
            return categories[selectedCategory].1
        } else {
            return allSymbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 검색바
                SearchBar(text: $searchText, placeholder: "SF Symbols 검색...")
                    .padding(.horizontal)
                
                if searchText.isEmpty {
                    // 카테고리 선택
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<categories.count, id: \.self) { index in
                                Button(action: {
                                    selectedCategory = index
                                }) {
                                    Text(categories[index].0)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == index ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(selectedCategory == index ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // 심볼 그리드
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 6), spacing: 16) {
                        ForEach(filteredSymbols, id: \.self) { symbolName in
                            Button(action: {
                                onSymbolSelected(symbolName)
                                isPresented = false
                            }) {
                                VStack {
                                    Image(systemName: symbolName)
                                        .font(.system(size: 30))
                                        .foregroundColor(.primary)
                                        .frame(width: 50, height: 50)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                    
                                    Text(symbolName)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("SF Symbols 스티커")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("취소") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// 검색바 컴포넌트
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

#Preview {
    SFSymbolsStickerView(isPresented: .constant(true)) { symbol in
        print("Selected symbol: \(symbol)")
    }
}
