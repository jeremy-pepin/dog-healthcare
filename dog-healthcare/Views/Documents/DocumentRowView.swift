import SwiftUI
import PDFKit

struct DocumentRowView: View {
    let document: Document

    var body: some View {
        HStack(spacing: 12) {
            // Miniature
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(thumbnailBackground)
                    .frame(width: 44, height: 56)

                if document.isPDF, let data = document.data {
                    PDFThumbnailView(data: data)
                        .frame(width: 40, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else if let data = document.data, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: document.isPDF ? "doc" : "photo")
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(document.title)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(document.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(document.date.fullDateFR)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: document.isPDF ? "doc.fill" : "photo.fill")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private var thumbnailBackground: Color {
        document.isPDF ? Color.red.opacity(0.1) : Color.blue.opacity(0.1)
    }
}

// Miniature PDF via PDFKit
struct PDFThumbnailView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFThumbnailView_UIKit {
        let view = PDFThumbnailView_UIKit()
        view.backgroundColor = .clear
        if let doc = PDFDocument(data: data), let page = doc.page(at: 0) {
            let size = CGSize(width: 40, height: 52)
            let image = page.thumbnail(of: size, for: .mediaBox)
            view.image = image
        }
        return view
    }

    func updateUIView(_ uiView: PDFThumbnailView_UIKit, context: Context) {}
}

class PDFThumbnailView_UIKit: UIView {
    var image: UIImage? {
        didSet { setNeedsDisplay() }
    }
    override func draw(_ rect: CGRect) {
        image?.draw(in: rect)
    }
}
