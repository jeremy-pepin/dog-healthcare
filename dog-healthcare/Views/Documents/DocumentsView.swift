import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

struct DocumentsView: View {
    let dog: Dog
    @Environment(\.modelContext) private var context

    @State private var showScanner = false
    @State private var showFilePicker = false
    @State private var showPhotosPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pendingData: Data?
    @State private var pendingFileType = "pdf"
    @State private var showAddForm = false
    @State private var documentToEdit: Document?

    private var groupedDocuments: [(category: String, docs: [Document])] {
        let sorted = (dog.documents ?? []).sorted { $0.date > $1.date }
        var groups: [String: [Document]] = [:]
        for doc in sorted {
            groups[doc.category, default: []].append(doc)
        }
        return groups
            .map { (category: $0.key, docs: $0.value) }
            .sorted { $0.category < $1.category }
    }

    var body: some View {
        NavigationStack {
            Group {
                if (dog.documents ?? []).isEmpty {
                    ContentUnavailableView {
                        Label("Aucun document", systemImage: "doc.badge.plus")
                    } description: {
                        Text("Scannez ou importez des factures,\nordonnances, radios…")
                    } actions: {
                        importMenu
                    }
                } else {
                    List {
                        ForEach(groupedDocuments, id: \.category) { group in
                            Section(group.category) {
                                ForEach(group.docs) { doc in
                                    NavigationLink {
                                        DocumentDetailView(document: doc)
                                    } label: {
                                        DocumentRowView(document: doc)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteDocument(doc)
                                        } label: {
                                            Label("Supprimer", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button { documentToEdit = doc } label: {
                                            Label("Modifier", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Documents")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    importMenu
                }
            }
            // Scanner
            .fullScreenCover(isPresented: $showScanner) {
                DocumentScannerView {
                    pendingData = $0
                    pendingFileType = "pdf"
                    showAddForm = true
                } onCancel: {
                    showScanner = false
                }
                .ignoresSafeArea()
            }
            // Import fichiers
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            // Import photos
            .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) {
                Task {
                    if let data = try? await selectedPhotoItem?.loadTransferable(type: Data.self) {
                        pendingData = data
                        pendingFileType = "image"
                        showAddForm = true
                    }
                    selectedPhotoItem = nil
                }
            }
            // Form après import
            .sheet(isPresented: $showAddForm) {
                if let data = pendingData {
                    AddDocumentView(dog: dog, pendingData: data, pendingFileType: pendingFileType)
                }
            }
            .sheet(item: $documentToEdit) { (doc: Document) in
                AddDocumentView(dog: dog, pendingData: doc.data, pendingFileType: doc.fileType, existingDocument: doc)
            }
        }
    }

    @ViewBuilder
    private var importMenu: some View {
        Menu {
            Button {
                showScanner = true
            } label: {
                Label("Scanner un document", systemImage: "doc.viewfinder")
            }

            Button {
                showPhotosPicker = true
            } label: {
                Label("Importer depuis Photos", systemImage: "photo.on.rectangle")
            }

            Button {
                showFilePicker = true
            } label: {
                Label("Importer depuis Fichiers", systemImage: "folder")
            }
        } label: {
            Image(systemName: "plus")
        }
    }

    private func deleteDocument(_ doc: Document) {
        dog.documents?.removeAll { $0.id == doc.id }
        context.delete(doc)
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let data = try? Data(contentsOf: url) else { return }
        let isImage = ["jpg", "jpeg", "png", "heic", "heif"].contains(url.pathExtension.lowercased())
        pendingData = data
        pendingFileType = isImage ? "image" : "pdf"
        showAddForm = true
    }
}
