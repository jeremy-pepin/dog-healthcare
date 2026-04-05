import SwiftData
import Foundation

@Model
final class Document {
    var title: String = ""
    var category: String = ""
    var date: Date = Date.now
    var fileType: String = ""     // "pdf" | "image"
    @Attribute(.externalStorage) var data: Data?
    var notes: String?
    var dog: Dog?
    var folder: DocumentFolder?

    init(title: String, category: String, date: Date, fileType: String, data: Data? = nil, notes: String? = nil) {
        self.title = title
        self.category = category
        self.date = date
        self.fileType = fileType
        self.data = data
        self.notes = notes
    }

    var isPDF: Bool { fileType == "pdf" }
}
