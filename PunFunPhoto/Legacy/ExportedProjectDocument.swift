import SwiftUI
import UniformTypeIdentifiers

struct ExportedProjectDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.punfunProject] } // ✅ .pfp는 사실상 zip
    static var writableContentTypes: [UTType] { [.punfunProject] }
    
    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

//extension UTType {
//    static var punfunProject: UTType {
//        UTType(importedAs: "com.punfunphoto.project")
//    }
//}
