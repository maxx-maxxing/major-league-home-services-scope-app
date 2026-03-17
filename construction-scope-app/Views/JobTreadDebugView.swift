import SwiftUI

#if DEBUG
struct JobTreadDebugView: View {
    @State private var statusMessage = "Idle"
    @State private var isLoading = false
    @State private var resultText: String = ""
    @State private var errorText: String = ""

    private let client = JobTreadClient()

    var body: some View {
        NavigationStack {
            List {
                Section("Connectivity Test") {
                    Text("Runs the JobTread `currentGrant` query using the Info.plist-backed debug configuration.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button {
                        runConnectivityTest()
                    } label: {
                        Label("Fetch Current Grant", systemImage: "network")
                    }
                    .disabled(isLoading)

                    HStack {
                        Text("Status")
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text(statusMessage)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    if !resultText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Result")
                                .font(.headline)

                            Text(resultText)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 4)
                    }

                    if !errorText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Error")
                                .font(.headline)

                            Text(errorText)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("JobTread Debug")
        }
    }

    private func runConnectivityTest() {
        isLoading = true
        statusMessage = "Loading..."
        resultText = ""
        errorText = ""

        Task {
            do {
                let currentGrant = try await client.fetchCurrentGrant()
                let formattedResult = formatCurrentGrant(currentGrant)
                await MainActor.run {
                    isLoading = false
                    statusMessage = "Success"
                    resultText = formattedResult
                }
                logCurrentGrant(currentGrant)
            } catch {
                await MainActor.run {
                    isLoading = false
                    statusMessage = "Failed"
                    errorText = error.localizedDescription
                }
                print("[JobTread] currentGrant request failed: \(error.localizedDescription)")
            }
        }
    }

    private func formatCurrentGrant(_ currentGrant: JobTreadCurrentGrant) -> String {
        var lines: [String] = [
            "Grant ID: \(currentGrant.id)",
            "User ID: \(currentGrant.user.id)",
            "User Name: \(currentGrant.user.name)",
            "Organizations:"
        ]

        if currentGrant.user.memberships.nodes.isEmpty {
            lines.append("- none")
        } else {
            for membership in currentGrant.user.memberships.nodes {
                lines.append("- \(membership.organization.name) (\(membership.organization.id))")
            }
        }

        return lines.joined(separator: "\n")
    }

    private func logCurrentGrant(_ currentGrant: JobTreadCurrentGrant) {
        print("[JobTread] currentGrant.id: \(currentGrant.id)")
        print("[JobTread] user.id: \(currentGrant.user.id)")
        print("[JobTread] user.name: \(currentGrant.user.name)")

        if currentGrant.user.memberships.nodes.isEmpty {
            print("[JobTread] memberships: none")
            return
        }

        for (index, membership) in currentGrant.user.memberships.nodes.enumerated() {
            print("[JobTread] membership[\(index)].organization.id: \(membership.organization.id)")
            print("[JobTread] membership[\(index)].organization.name: \(membership.organization.name)")
        }
    }
}
#endif
