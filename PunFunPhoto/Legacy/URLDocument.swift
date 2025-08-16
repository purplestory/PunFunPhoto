import SwiftUI
import UniformTypeIdentifiers

struct URLDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.item] }

    let url: URL

    init(url: URL) {
        self.url = url
    }

    init(configuration: ReadConfiguration) throws {
        self.url = URL(fileURLWithPath: "")
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: url, options: .immediate)
    }
}
