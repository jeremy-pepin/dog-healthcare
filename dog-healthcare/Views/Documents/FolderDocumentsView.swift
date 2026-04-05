import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

private struct PendingDocument: Identifiable {
    let id = UUID()
    let data: Data
    let fileType: String
}

struct FolderDocumentsView: View {
    let dog: Dog
    @Bindable var folder: DocumentFolder
    @Environment(\.modelContext) private var context

    @State private var showScanner = false
    @State private var showFilePicker = false
    @State private var showPhotosPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var scannedData: Data?
    @State private var pendingDocument: PendingDocument?
    @State private var documentToEdit: Document?

    // Renommer le dossier
    @State private var showRenameAlert = false
    @State private var renameText = ""

    private var groupedDocuments: [(category: String, docs: [Document])] {
        let sorted = (folder.documents ?? []).sorted { $0.date > $1.date }
        var groups: [String: [Document]] = [:]
        for doc in sorted {
            groups[doc.category, default: []].append(doc)
        }
        return groups
            .map { (category: $0.key, docs: $0.value) }
            .sorted { $0.category < $1.category }
    }

    var body: some View {
        Group {
            if (folder.documents ?? []).isEmpty {
                ContentUnavailableView {
                    Label("Dossier vide", systemImage: "doc.badge.plus")
                } description: {
                    Text("Scannez ou importez des documents\ndans ce dossier.")
                } actions: {
                    // Menu sans .borderedProminent : le style natif de ContentUnavailableView
                    // gère lui-même le contraste en mode clair et sombre.
                    Menu {
                        importMenuContent
                    } label: {
                        Label("Importer un document", systemImage: "doc.badge.plus")
                    }
                    .buttonStyle(.bordered)
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
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            // Une seule icône "..." qui regroupe import ET actions dossier
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Section("Importer") {
                        importMenuContent
                    }
                    Section {
                        Button {
                            renameText = folder.name
                            showRenameAlert = true
                        } label: {
                            Label("Renommer le dossier", systemImage: "pencil")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        // Alerte renommer
        .alert("Renommer le dossier", isPresented: $showRenameAlert) {
            TextField("Nom", text: $renameText)
            Button("Annuler", role: .cancel) {}
            Button("Renommer") { applyRename() }
        }
        // Scanner
        .fullScreenCover(isPresented: $showScanner, onDismiss: {
            if let data = scannedData {
                pendingDocument = PendingDocument(data: data, fileType: "pdf")
                scannedData = nil
            }
        }) {
            DocumentScannerView {
                scannedData = $0
                showScanner = false
            } onCancel: {
                showScanner = false
            }
            .ignoresSafeArea()
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) {
            Task {
                if let data = try? await selectedPhotoItem?.loadTransferable(type: Data.self) {
                    pendingDocument = PendingDocument(data: data, fileType: "image")
                }
                selectedPhotoItem = nil
            }
        }
        .sheet(item: $pendingDocument) { pending in
            AddDocumentView(dog: dog, pendingData: pending.data, pendingFileType: pending.fileType, preselectedFolder: folder)
        }
        .sheet(item: $documentToEdit) { doc in
            AddDocumentView(dog: dog, pendingData: doc.data, pendingFileType: doc.fileType, existingDocument: doc)
        }
    }

    @ViewBuilder
    private var importMenuContent: some View {
        Button { showScanner = true } label: {
            Label("Scanner un document", systemImage: "doc.viewfinder")
        }
        Button { showPhotosPicker = true } label: {
            Label("Importer depuis Photos", systemImage: "photo.on.rectangle")
        }
        Button { showFilePicker = true } label: {
            Label("Importer depuis Fichiers", systemImage: "folder")
        }
    }

    private func applyRename() {
        let name = renameText.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        folder.name = name
        try? context.save()
    }

    private func deleteDocument(_ doc: Document) {
        folder.documents?.removeAll { $0.id == doc.id }
        dog.documents?.removeAll { $0.id == doc.id }
        context.delete(doc)
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else { return }
        let isImage = ["jpg", "jpeg", "png", "heic", "heif"].contains(url.pathExtension.lowercased())
        pendingDocument = PendingDocument(data: data, fileType: isImage ? "image" : "pdf")
    }
}
