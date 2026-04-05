import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

/// Enveloppe identifiable pour déclencher la sheet d'ajout de document.
private struct PendingDocument: Identifiable {
    let id = UUID()
    let data: Data
    let fileType: String
}

struct DocumentsView: View {
    let dog: Dog
    @Environment(\.modelContext) private var context

    @State private var showScanner = false
    @State private var showFilePicker = false
    @State private var showPhotosPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var scannedData: Data?
    @State private var pendingDocument: PendingDocument?
    @State private var documentToEdit: Document?

    // Gestion des dossiers
    @State private var showNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var folderToRename: DocumentFolder?
    @State private var renameText = ""

    private var sortedFolders: [DocumentFolder] {
        (dog.documentFolders ?? []).sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var uncategorizedDocs: [Document] {
        (dog.documents ?? [])
            .filter { $0.folder == nil }
            .sorted { $0.date > $1.date }
    }

    private var isEmpty: Bool {
        sortedFolders.isEmpty && uncategorizedDocs.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if isEmpty {
                    ContentUnavailableView {
                        Label("Aucun document", systemImage: "doc.badge.plus")
                    } description: {
                        Text("Scannez ou importez des factures,\nordonnances, radios…")
                    } actions: {
                        importMenu
                        Button {
                            newFolderName = ""
                            showNewFolderAlert = true
                        } label: {
                            Label("Nouveau dossier", systemImage: "folder.badge.plus")
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    List {
                        // Section dossiers
                        if !sortedFolders.isEmpty {
                            Section("Dossiers") {
                                ForEach(sortedFolders) { folder in
                                    NavigationLink {
                                        FolderDocumentsView(dog: dog, folder: folder)
                                    } label: {
                                        FolderRowView(folder: folder)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteFolder(folder)
                                        } label: {
                                            Label("Supprimer", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            renameText = folder.name
                                            folderToRename = folder
                                        } label: {
                                            Label("Renommer", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            }
                        }

                        // Documents sans dossier
                        if !uncategorizedDocs.isEmpty {
                            Section("Sans dossier") {
                                ForEach(uncategorizedDocs) { doc in
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
                    Menu {
                        Section("Importer") {
                            importMenuContent
                        }
                        Section {
                            Button {
                                newFolderName = ""
                                showNewFolderAlert = true
                            } label: {
                                Label("Nouveau dossier", systemImage: "folder.badge.plus")
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            // Alerte nouveau dossier
            .alert("Nouveau dossier", isPresented: $showNewFolderAlert) {
                TextField("Nom du dossier", text: $newFolderName)
                Button("Annuler", role: .cancel) {}
                Button("Créer") { createFolder() }
            }
            // Alerte renommer dossier
            .alert("Renommer le dossier", isPresented: Binding(
                get: { folderToRename != nil },
                set: { if !$0 { folderToRename = nil } }
            )) {
                TextField("Nom", text: $renameText)
                Button("Annuler", role: .cancel) { folderToRename = nil }
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
                AddDocumentView(dog: dog, pendingData: pending.data, pendingFileType: pending.fileType)
            }
            .sheet(item: $documentToEdit) { doc in
                AddDocumentView(dog: dog, pendingData: doc.data, pendingFileType: doc.fileType, existingDocument: doc)
            }
        }
    }

    @ViewBuilder
    private var importMenu: some View {
        // .bordered plutôt que .borderedProminent : ContentUnavailableView ne gère pas
        // correctement le contraste texte/fond de .borderedProminent en mode sombre.
        Menu {
            importMenuContent
        } label: {
            Label("Importer", systemImage: "doc.badge.plus")
        }
        .buttonStyle(.bordered)
    }

    @ViewBuilder
    private var importMenuContent: some View {
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
    }

    private func createFolder() {
        let name = newFolderName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let folder = DocumentFolder(name: name)
        folder.dog = dog
        dog.documentFolders = (dog.documentFolders ?? []) + [folder]
        context.insert(folder)
        try? context.save()
    }

    private func applyRename() {
        let name = renameText.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, let folder = folderToRename else { return }
        folder.name = name
        try? context.save()
        folderToRename = nil
    }

    private func deleteFolder(_ folder: DocumentFolder) {
        dog.documentFolders?.removeAll { $0.id == folder.id }
        context.delete(folder)
        try? context.save()
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
        pendingDocument = PendingDocument(data: data, fileType: isImage ? "image" : "pdf")
    }
}

// MARK: - FolderRowView

private struct FolderRowView: View {
    let folder: DocumentFolder

    private var docCount: Int { (folder.documents ?? []).count }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundStyle(.yellow)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(folder.name)
                    .font(.headline)
                Text("\(docCount) document\(docCount != 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
