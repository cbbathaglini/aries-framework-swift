import SwiftUI
import AriesFramework

struct CredentialDetailLoaderView: View {
    let credentialId: String

    @State private var credential: CredentialInfo?
    @State private var failed = false

    var body: some View {
        Group {
            if let credential = credential {
                CredentialDetailView(credential: credential)
            } else if failed {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.largeTitle)
                    Text("Unable to load credential details.")
                        .font(.headline)
                    Text("Please try again later.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
            } else {
                VStack(spacing: 16) {
                    ProgressView("Loading credential details...")
                    Text("Please wait while we fetch the information.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            Task { await load() }
        }
    }

    private func load() async {
        guard let agent = agent else {
            await MainActor.run { failed = true }
            return
        }

        do {
            print("Loading credential details for id: \(credentialId)")
            let record: CredentialExchangeRecord = try await agent.credentialExchangeRepository.getById(credentialId)

                let attributesDict = Dictionary(
                    uniqueKeysWithValues: (record.credentialAttributes ?? []).map { ($0.name, $0.value) }
                )

                let recordTypes = record.credentials.map { $0.credentialRecordType }

                await MainActor.run {
                    credential = CredentialInfo(
                        id: record.id,
                        w3cId: record.w3cCredentialId ?? "not informed",
                        attrs: attributesDict,
                        schema_id: record.schemaId,
                        type: recordTypes,
                        state: record.state,
                        credentialDefinitionId: record.credentialDefinitionId ?? "not informed",
                        revRegId: record.revRegId ?? "not revokable",
                        createdAt: record.createdAt,
                        isRevoked: record.state == .Revoked
                    )
                }
        } catch {
            print("Error loading credential details: \(error)")
            await MainActor.run { failed = true }
        }
    }
}
