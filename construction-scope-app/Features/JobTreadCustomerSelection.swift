import SwiftUI

@MainActor
final class JobTreadCustomerSearchViewModel: ObservableObject {
    static let minimumLiveSearchCharacters = 2

    @Published var query = ""
    @Published private(set) var results: [JobTreadCustomerLookupResult] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasSearched = false
    @Published var errorMessage: String?

    private let customerSearcher: JobTreadCustomerSearching
    private var scheduledSearchTask: Task<Void, Never>?
    private var activeSearchID = UUID()

    init(customerSearcher: JobTreadCustomerSearching = JobTreadClient()) {
        self.customerSearcher = customerSearcher
    }

    deinit {
        scheduledSearchTask?.cancel()
    }

    func search() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        print("[JobTreadSearchVM] search requested query='\(trimmedQuery)'")
        hasSearched = true
        errorMessage = nil

        guard !trimmedQuery.isEmpty else {
            print("[JobTreadSearchVM] empty query; resetting search state")
            resetSearchState(clearQuery: false)
            return
        }

        scheduledSearchTask = nil
        let searchID = UUID()
        activeSearchID = searchID
        isLoading = true
        print("[JobTreadSearchVM] loading started searchID=\(searchID) query='\(trimmedQuery)'")

        defer {
            if activeSearchID == searchID {
                isLoading = false
                print("[JobTreadSearchVM] loading cleared searchID=\(searchID) query='\(trimmedQuery)'")
            } else {
                print("[JobTreadSearchVM] skipping loading clear for stale searchID=\(searchID)")
            }
        }

        do {
            let results = try await customerSearcher.searchCustomers(matching: trimmedQuery, limit: 20)
            guard activeSearchID == searchID else {
                print("[JobTreadSearchVM] ignoring stale success searchID=\(searchID)")
                return
            }

            self.results = results
            print("[JobTreadSearchVM] search success searchID=\(searchID) results=\(results.count)")
        } catch {
            guard activeSearchID == searchID else {
                print("[JobTreadSearchVM] ignoring stale failure searchID=\(searchID)")
                return
            }

            results = []
            errorMessage = error.localizedDescription
            print("[JobTreadSearchVM] search failure searchID=\(searchID) error='\(error.localizedDescription)'")
        }
    }

    func scheduleLiveSearch() {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        scheduledSearchTask?.cancel()
        scheduledSearchTask = nil
        errorMessage = nil

        guard !trimmedQuery.isEmpty else {
            print("[JobTreadSearchVM] live search reset for empty query")
            resetSearchState(clearQuery: false)
            return
        }

        guard trimmedQuery.count >= Self.minimumLiveSearchCharacters else {
            hasSearched = false
            results = []
            isLoading = false
            print("[JobTreadSearchVM] live search waiting for more input query='\(trimmedQuery)'")
            return
        }

        print("[JobTreadSearchVM] scheduling live search query='\(trimmedQuery)'")
        scheduledSearchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await self?.search()
        }
    }

    func submitSearch() {
        scheduledSearchTask?.cancel()
        scheduledSearchTask = nil
        print("[JobTreadSearchVM] submit search query='\(query.trimmingCharacters(in: .whitespacesAndNewlines))'")
        Task {
            await search()
        }
    }

    private func resetSearchState(clearQuery: Bool) {
        scheduledSearchTask?.cancel()
        scheduledSearchTask = nil
        activeSearchID = UUID()
        if clearQuery {
            query = ""
        }
        results = []
        hasSearched = false
        isLoading = false
        errorMessage = nil
        print("[JobTreadSearchVM] search state reset clearQuery=\(clearQuery)")
    }
}

struct ScopeCreationSheet: View {
    let onCreateBlankScope: () -> Void
    let onCreateScopeFromCustomer: (JobTreadCustomerLookupResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = JobTreadCustomerSearchViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Search for an existing JobTread customer, then create a new scope linked to that record.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Label {
                            TextField("Search JobTread customers", text: $viewModel.query)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .onSubmit {
                                    viewModel.submitSearch()
                                }
                        } icon: {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                        }

                        Button("Search") {
                            viewModel.submitSearch()
                        }
                        .disabled(viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                    }
                    .frame(minHeight: 44)

                    if !viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                        viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).count < JobTreadCustomerSearchViewModel.minimumLiveSearchCharacters {
                        Text("Type at least \(JobTreadCustomerSearchViewModel.minimumLiveSearchCharacters) characters to see live matches, or submit a full exact name.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if viewModel.isLoading {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Searching JobTread...")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                } header: {
                    Text("Create from JobTread Customer")
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    } header: {
                        Text("Lookup Error")
                    }
                }

                if !viewModel.results.isEmpty {
                    Section {
                        ForEach(viewModel.results) { customer in
                            Button {
                                onCreateScopeFromCustomer(customer)
                                dismiss()
                            } label: {
                                JobTreadCustomerResultRow(customer: customer)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("Matching Customers")
                    }
                } else if viewModel.hasSearched && !viewModel.isLoading && viewModel.errorMessage == nil {
                Section {
                        ContentUnavailableView(
                            "No Customers Found",
                            systemImage: "person.crop.circle.badge.xmark",
                            description: Text("Try a different customer name search.")
                        )
                    }
                }

                Section {
                    Button {
                        onCreateBlankScope()
                        dismiss()
                    } label: {
                        Label("Blank Local Scope", systemImage: "doc.badge.plus")
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }

                    Text("Temporary fallback when JobTread lookup is unavailable or when you need to start from a blank scope.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Temporary Fallback")
                }
            }
            .scrollContentBackground(.hidden)
            .background(LiquidGlassBackdrop())
            .navigationTitle("New Scope")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationBackground(.clear)
        .onChange(of: viewModel.query) { _, _ in
            viewModel.scheduleLiveSearch()
        }
    }
}

private struct JobTreadCustomerResultRow: View {
    let customer: JobTreadCustomerLookupResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(customer.resolvedDisplayName)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)

            if let address = customer.primaryAddress?.trimmingCharacters(in: .whitespacesAndNewlines), !address.isEmpty {
                Text(address)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            let metadata = [customer.phone, customer.email]
                .compactMap { value in
                    value?.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                .filter { !$0.isEmpty }
                .joined(separator: " • ")

            if !metadata.isEmpty {
                Text(metadata)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }
}
