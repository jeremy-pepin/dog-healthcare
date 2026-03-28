import SwiftUI
import SwiftData
import PDFKit

struct DocumentDetailView: View {
    @Bindable var document: Document
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            if document.isPDF {
                PDFViewerView(data: document.data)
            } else if let uiImage = UIImage(data: document.data) {
                ScrollView([.horizontal, .vertical]) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                }
            } else {
                ContentUnavailableView("Impossible d'afficher le document", systemImage: "doc.badge.exclamationmark")
            }
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ShareLink(
                        item: document.data,
                        preview: SharePreview(document.title, image: Image(systemName: document.isPDF ? "doc.fill" : "photo.fill"))
                    ) {
                        Label("Partager", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showEdit = true
                    } label: {
                        Label("Modifier", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Supprimer", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            AddDocumentView(
                dog: document.dog!,
                pendingData: document.data,
                pendingFileType: document.fileType,
                existingDocument: document
            )
        }
        .confirmationDialog("Supprimer ce document ?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Supprimer", role: .destructive) {
                if let dog = document.dog {
                    dog.documents.removeAll { $0.id == document.id }
                }
                context.delete(document)
                dismiss()
            }
            Button("Annuler", role: .cancel) {}
        }
    }
}

struct PDFViewerView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .clear
        if let doc = PDFDocument(data: data) {
            pdfView.document = doc
        }
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}
