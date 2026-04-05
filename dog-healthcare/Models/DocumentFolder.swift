import SwiftData
import Foundation

@Model
final class DocumentFolder {
    var name: String = ""
    var createdAt: Date = Date.now
    var dog: Dog?

    @Relationship(deleteRule: .nullify, inverse: \Document.folder)
    var documents: [Document]? = []

    init(name: String) {
        self.name = name
    }
}
