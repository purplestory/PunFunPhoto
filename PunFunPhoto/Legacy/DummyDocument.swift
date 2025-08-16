import SwiftUI
import UniformTypeIdentifiers

struct DummyDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.punfunProject] }

    init(configuration: ReadConfiguration) throws {
        print("📄 DummyDocument init called with file: \(configuration.file)")
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data("hello".utf8))
    }
}
