import SwiftUI

@MainActor
final class JobTreadCustomerSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var results: [JobTreadCustomerLookupResult] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasSearched = false
    @Published var errorMessage: String?

    private let customerSearcher: JobTreadCustomerSearching

    init(customerSearcher: JobTreadCustomerSearching = JobTreadClient()) {
        self.customerSearcher = customerSearcher
    }

    func search() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        hasSearched = true
        errorMessage = nil

        guard !trimmedQuery.isEmpty else {
            results = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            results = try await customerSearcher.searchCustomers(matching: trimmedQuery, limit: 20)
        } catch {
            results = []
            errorMessage = error.localizedDescription
        }
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
                                    Task {
                                        await viewModel.search()
                                    }
                                }
                        } icon: {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                        }

                        Button("Search") {
                            Task {
                                await viewModel.search()
                            }
                        }
                        .disabled(viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                    }
                    .frame(minHeight: 44)

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
