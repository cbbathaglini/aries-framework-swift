import SwiftUI
import AriesFramework

struct RequestProofView: View {
    let presentationMessageId: String?
    let proofRecordId: String?
    let status: NotificationType?
       
    @State private var proofRequest: AnonCredsProofRequest?
    @State private var copiedText: String? = nil
    @State private var isLoading = true

    @State private var availableCredentials: [CredentialInfo] = []
    @State private var selectedCredentialId: String? = nil
    @State private var isSendingProof = false
    @State private var errorMessage: String? = nil
    @State private var proofState: ProofState = .None
    @State private var chosenCredentialId: String? = nil

    init(presentationMessageId: String? = nil, proofRecordId: String? = nil, status: NotificationType? = nil) {
        self.presentationMessageId = presentationMessageId
        self.proofRecordId = proofRecordId
        self.status = status
    }
    
    var body: some View {
        Group {
            
            if isLoading {
                VStack {
                    ProgressView("Loading proof details...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                    Text("Please wait while we fetch the information.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            } else if let proof = proofRequest {
                
                
                List {
                    
                    if proofState != .None {
                        let state = proofState
                        let (icon, bgColor, borderColor, textColor, message): (String, Color, Color, Color, String) = {
                            switch state {
                            case .Abandoned, .Declined:
                                return ("xmark.octagon.fill",
                                        Color.red.opacity(0.15),
                                        Color.red.opacity(0.3),
                                        .red,
                                        "Proof declined or abandoned.")

                            case .ProposalSent, .ProposalReceived:
                                return ("arrow.up.right.circle.fill",
                                        Color.orange.opacity(0.15),
                                        Color.orange.opacity(0.3),
                                        .orange,
                                        "Proof in proposal stage (\(state.rawValue)).")

                            case .RequestSent, .RequestReceived:
                                return ("envelope.fill",
                                        Color.purple.opacity(0.15),
                                        Color.purple.opacity(0.3),
                                        .purple,
                                        "Proof in request stage (\(state.rawValue)).")

                            case .PresentationSent, .PresentationReceived:
                                return ("paperplane.fill",
                                        Color.blue.opacity(0.15),
                                        Color.blue.opacity(0.3),
                                        .blue,
                                        "Proof in presentation stage (\(state.rawValue)).")

                            case .Done:
                                return ("checkmark.seal.fill",
                                        Color.green.opacity(0.15),
                                        Color.green.opacity(0.3),
                                        .green,
                                        "✅ Proof completed and verified.")

                            default:
                                return ("questionmark.circle.fill",
                                        Color.gray.opacity(0.15),
                                        Color.gray.opacity(0.3),
                                        .gray,
                                        "Proof state: \(state.rawValue)")
                            }
                        }()

                        HStack {
                            Image(systemName: icon)
                                .foregroundColor(textColor)
                            Text(message)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(textColor)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(bgColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderColor, lineWidth: 1)
                        )
                        .padding(.vertical, 8)
                    }
                    
                    Section(header: Text("Proof Information")) {
                                                
                        HStack {
                            Text("Presentation ID")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(presentationMessageId ?? proofRecordId ?? "—")
                                .foregroundColor(.secondary)
                            Button(action: {
                                if let id = presentationMessageId ?? proofRecordId {
                                    copyToClipboard(id)
                                }
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        HStack {
                            Text("Nonce")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(proof.nonce)
                                .foregroundColor(.secondary)
                            Button(action: { copyToClipboard(proof.nonce) }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.blue)
                            }
                        }

                        if let nonRevoked = proof.nonRevoked {
                            HStack {
                                Text("Validity Period")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(formatRevocationPeriod(nonRevoked))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Section(header: Text("Requested Attributes")) {
                        if proof.requestedAttributes.isEmpty {
                            Text("No requested attributes.")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(proof.requestedAttributes.sorted(by: { $0.key < $1.key }), id: \.key) { key, attr in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: "info.circle.fill")
                                                .foregroundColor(.blue)
                                            Text(attr.name ?? key)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                        }

                                        if let names = attr.names {
                                            VStack(alignment: .leading, spacing: 4) {
                                                ForEach(names, id: \.self) { n in
                                                    Text("• \(n)")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }

                                        if let restrictions = attr.restrictions {
                                            Divider().padding(.vertical, 4)
                                            VStack(alignment: .leading, spacing: 4) {
                                                ForEach(restrictions.indices, id: \.self) { i in
                                                    let r = restrictions[i]
                                                    if let schema = r.schemaName {
                                                        HStack {
                                                            Image(systemName: "doc.text.fill")
                                                                .foregroundColor(.gray)
                                                            Text("Schema: \(schema)")
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                        }
                                                    }
                                                    if let credDefId = r.credDefId {
                                                        HStack {
                                                            Image(systemName: "key.fill")
                                                                .foregroundColor(.gray)
                                                            Text("CredDefId: \(credDefId)")
                                                                .font(.caption2)
                                                                .foregroundColor(.gray)
                                                                .lineLimit(1)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Section(header: Text("Requested Predicates")) {
                        if proof.requestedPredicates.isEmpty {
                            Text("No requested predicates.")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(proof.requestedPredicates.sorted(by: { $0.key < $1.key }), id: \.key) { key, pred in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: "function")
                                                .foregroundColor(.purple)
                                            Text(pred.name ?? key)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                        }

                                        HStack {
                                            Text("Condition:")
                                                .fontWeight(.semibold)
                                            Spacer()
                                            Text("\(pred.pType.rawValue) \(pred.pValue.description)")
                                                .foregroundColor(.secondary)
                                        }

                                        if let restrictions = pred.restrictions {
                                            Divider().padding(.vertical, 4)
                                            VStack(alignment: .leading, spacing: 4) {
                                                ForEach(restrictions.indices, id: \.self) { i in
                                                    let r = restrictions[i]
                                                    if let schema = r.schemaName {
                                                        HStack {
                                                            Image(systemName: "doc.text.fill")
                                                                .foregroundColor(.gray)
                                                            Text("Schema: \(schema)")
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                        }
                                                    }
                                                    if let credDefId = r.credDefId {
                                                        HStack {
                                                            Image(systemName: "key.fill")
                                                                .foregroundColor(.gray)
                                                            Text("CredDefId: \(credDefId)")
                                                                .font(.caption2)
                                                                .foregroundColor(.gray)
                                                                .lineLimit(1)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    if status != NotificationType.declineProofv2 {
                        Section(header: Text("Select Credential")) {
                            if availableCredentials.isEmpty {
                                Text("No compatible credentials found.")
                                    .foregroundColor(.gray)
                            } else {
                                Picker("Credential", selection: $selectedCredentialId) {
                                    Text("Select a credential")
                                        .tag(nil as String?)
                                    
                                    ForEach(availableCredentials, id: \.id) { cred in
                                        Text("Credential \(cred.id)")
                                            .tag(Optional(cred.id))
                                    }
                                }
                                .pickerStyle(.menu)
                                .disabled(chosenCredentialId != nil)
                                .onAppear {
                                    if let chosen = chosenCredentialId,
                                       availableCredentials.contains(where: { $0.id == chosen }) {
                                        selectedCredentialId = chosen
                                    }
                                }
                            }
                        }
                    }

                    if selectedCredentialId != nil && proofState != .Done {
                        Section {
                            Button(action: {
                                Task { await acceptProof() }
                            }) {
                                if isSendingProof {
                                    ProgressView()
                                } else {
                                    Text("✅ Accept and Send Proof")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }

                    if let error = errorMessage {
                        Section {
                            Text("❌ \(error)")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                }
            } else {
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.largeTitle)
                        .padding(.bottom, 8)
                    Text("Unable to load proof details.")
                        .font(.headline)
                    Text("Please try again later.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("Proof Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProofDetails()
            await loadAvailableCredentials()
        }
    }

    private func loadProofDetails() async {
        do {
            var record: ProofExchangeRecord? = nil
            
            if let presentationId = presentationMessageId, !presentationId.isEmpty {
                record = try await agent?.proofRepository.getByPresentationMessageId(presentationId)
            }
            
            if record == nil, let proofId = proofRecordId, !proofId.isEmpty {
                record = try await agent?.proofRepository.getById(proofId)
            }
            
            guard let record = record else {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "❌ No proof found."
                }
                return
            }
            
            proofState = record.state
            
            self.chosenCredentialId = record.chosenCredentialId
            if let chosen = record.chosenCredentialId {
                print("📎 chosenCredentialId found: \(chosen)")
                self.selectedCredentialId = chosen
            }
            
            var verifierRecord: VerifierRecord? = nil

            print("🔍 nonRevoked:", verifierRecord?.proofRequest?.nonRevoked as Any)
            if let threadId = record.threadId as String? {
                verifierRecord = try? await agent?.verifierRepository.getByGlobalThreadId(globalThreadId: threadId)
            }
            
            await MainActor.run {
                self.proofRequest = verifierRecord?.proofRequest
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Error loading proof details: \(error.localizedDescription)"
            }
        }
    }

    private func loadAvailableCredentials() async {
        do {
            guard let proof = proofRequest else { return }
            guard let allRecords = await agent?.credentialExchangeRepository.getAll() else { return }
            
            
            let requestedCredDefIds: [String] = proof.requestedAttributes.values
                .compactMap { $0.restrictions?.compactMap { $0.credDefId } }
                .flatMap { $0 }
            
            let requestedCredDefIdsPredicates: [String] = proof.requestedPredicates.values
                .compactMap { $0.restrictions?.compactMap { $0.credDefId } }
                .flatMap { $0 }
            
            let requestedAttrNames: [String] = proof.requestedAttributes.values
                .compactMap { attr in
                    if let names = attr.names { return names }
                    if let name = attr.name { return [name] }
                    return []
                }
                .flatMap { $0 }
            
            
            var compatible: [CredentialInfo] = []
            
            for record in allRecords {
                
                let hasInterval = (proof.nonRevoked?.from != nil) || (proof.nonRevoked?.to != nil)
                
                if hasInterval{
                    let intervalFrom: UInt64 = proof.nonRevoked?.from ?? 0
                    let intervalTo: UInt64   = proof.nonRevoked?.to   ?? UInt64.max
                    
                    if record.revocationNotification?.revocationDate == nil {
                        print("No revocation — valid credential")
                    } else {
                        let revocationDate = record.revocationNotification!.revocationDate
                        let realTimestampUnix = Int64(revocationDate.timeIntervalSince1970)
                        
                        //data revoga = 13:42
                        // interval = 13:44
                        
                        let wasRevokedWithinInterval =
                            realTimestampUnix <= intervalTo

                        if wasRevokedWithinInterval {
                            print("❌ Credential revoked within interval — ignoring")
                            continue
                        }

                        print("✅ Credential valid — revoked outside interval or never revoked")
                    }
                }
                
                else if !hasInterval {
                    if record.state == .Revoked {
                        print("❌ Credential revoked — ignoring (no interval defined)")
                        continue
                    }
                }
                
                guard let recordCredDefId = record.credentialDefinitionId else { continue }
                
                let attributesDict = Dictionary(
                    uniqueKeysWithValues: (record.credentialAttributes ?? [])
                        .map { ($0.name, $0.value) }
                )
                
                let hasAllAttributes = requestedAttrNames.allSatisfy {
                    attributesDict.keys.contains($0)
                }
                
                let matchesCredDefAttr =
                    requestedCredDefIds.isEmpty || requestedCredDefIds.contains(recordCredDefId)
                
                let matchesCredDefPredicates =
                    requestedCredDefIdsPredicates.isEmpty || requestedCredDefIdsPredicates.contains(recordCredDefId)
                
                let allPredicatesSatisfied = proof.requestedPredicates.values.allSatisfy { predicate in
                    let attrName = predicate.name
                    guard let rawValue = attributesDict[attrName],
                          let attrValue = Int(rawValue) else { return false }
                    
                    switch predicate.pType {
                        case .GreaterThanOrEqualTo: return attrValue >= predicate.pValue
                        case .LessThanOrEqualTo:   return attrValue <= predicate.pValue
                        case .GreaterThan:         return attrValue > predicate.pValue
                        case .LessThan:            return attrValue < predicate.pValue
                        default:                   return false
                    }
                }
                
                guard hasAllAttributes && matchesCredDefAttr && matchesCredDefPredicates && allPredicatesSatisfied else { continue }
                
                let recordTypes = record.credentials.map { $0.credentialRecordType }
                
                let info = CredentialInfo(
                    id: record.id,
                    attrs: attributesDict,
                    schema_id: record.schemaId,
                    type: recordTypes,
                    credentialDefinitionId: record.credentialDefinitionId ?? "not informed",
                    revRegId: record.revRegId ?? "not revokable",
                    createdAt: record.createdAt
                )
                
                compatible.append(info)
            }
            
            await MainActor.run {
                self.availableCredentials = compatible
                if let selectedCredentialId,
                   !compatible.contains(where: { $0.id == selectedCredentialId }) {
                    self.selectedCredentialId = nil
                }
            }
            
        } catch {
            print("Error: \(error)")
        }
    }

    private func acceptProof() async {
        guard let selectedCredentialId = selectedCredentialId else { return }

        await MainActor.run {
            isSendingProof = true
            errorMessage = nil
        }

        do {
            print("📤 Sending proof with credential: \(selectedCredentialId)")
            await CredentialHandler.shared.sendProof(version: "2.0", proofRecordId: proofRecordId!, chosenCredentialId: selectedCredentialId)

            await MainActor.run {
                isSendingProof = false
                proofState = ProofState.Done
            }
        } catch {
            await MainActor.run {
                isSendingProof = false
                errorMessage = "Error sending proof: \(error.localizedDescription)"
            }
        }
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        copiedText = "Copied!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copiedText = nil
        }
    }

    private func formatRevocationPeriod(_ nonRevoked: AnonCredsNonRevokedInterval) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let fromTime = nonRevoked.from.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        let toTime = nonRevoked.to.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        switch (fromTime, toTime) {
        case let (from?, to?): return "\(formatter.string(from: from)) → \(formatter.string(from: to))"
        case let (from?, nil): return "From \(formatter.string(from: from))"
        case let (nil, to?): return "Until \(formatter.string(from: to))"
        default: return "No interval defined"
        }
    }
}
