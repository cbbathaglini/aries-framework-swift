import SwiftUI
import CodeScanner
import AriesFramework

struct VerifierProofView: View {
    @State private var scannedJSON: String?
    @State private var statusMessage = "Point the camera at the requester's QR code."
    @State private var presentationResult: [String: Any]?
    @State private var isProcessing = false
    @State private var proofRequest: AnonCredsProofRequest?
    @State private var availableCredentials: [CredentialInfo] = []
    @State private var selectedCredentialId: String?
    @State private var proofRecord: ProofExchangeRecord?
    
    @State private var qrParts: [UIImage] = []

    // store all generated qrcodes
    @State private var qrCodes: [UIImage] = []

    @StateObject private var proofHandler = ProofHandler.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("📷 Scan Proof Request QR Code")
                    .font(.title2)
                    .bold()
                
                // SCAN
                if scannedJSON == nil {
                    CodeScannerView(codeTypes: [.qr]) { result in
                        switch result {
                        case .success(let code):
                            Task { await handleScanned(code: code.string) }
                        case .failure(let error):
                            statusMessage = "Error reading QR: \(error.localizedDescription)"
                        }
                    }
                    .frame(height: 320)
                    .cornerRadius(12)
                    .shadow(radius: 4)
                } else {
                    ScrollView {
                        Text("📥 Proof Request received:")
                            .font(.headline)
                        
                        Text(scannedJSON ?? "")
                            .font(.footnote)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .textSelection(.enabled)
                    }
                    .frame(height: 200)
                }
                
                // List of credentials
                if !availableCredentials.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select a compatible credential:")
                            .font(.headline)
                        
                        Picker("Credential", selection: $selectedCredentialId) {
                            Text("Choose...").tag(nil as String?)
                            ForEach(availableCredentials, id: \.id) { cred in
                                VStack(alignment: .leading) {
                                    Text("📄 \(cred.id ?? "No schema")")
                                        .font(.subheadline)
                                    ForEach(cred.attrs.keys.sorted(), id: \.self) { key in
                                        Text("• \(key): \(cred.attrs[key] ?? "")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .tag(Optional(cred.id))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding(.horizontal)
                }
                
                if let selectedCredentialId = selectedCredentialId, !selectedCredentialId.isEmpty {
                    Button(action: { Task { await generatePresentation() } }) {
                        if isProcessing {
                            ProgressView()
                        } else {
                            Text("✅ Generate Presentation with Selected Credential")
                                .fontWeight(.semibold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // RESULT JSON
                if let presentationResult {
                    Divider()
                    Text("✅ Proof Presentation Generated")
                        .font(.headline)
                    ScrollView {
                        Text(prettyJSONString(from: presentationResult))
                            .font(.footnote)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .textSelection(.enabled)
                    }
                    
                    
                    if !qrCodes.isEmpty {
                        Divider()
                        Text("📡 Generated QR Codes")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: true) {
                            HStack(spacing: 20) {
                                ForEach(Array(qrCodes.enumerated()), id: \.offset) { idx, qr in
                                    VStack {
                                        Text("QR \(idx+1)/\(qrCodes.count)")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                        
                                        Image(uiImage: qr)
                                            .resizable()
                                            .interpolation(.none)
                                            .scaledToFit()
                                            .frame(width: 240, height: 240)
                                            .padding(12)
                                            .background(Color.white)
                                            .cornerRadius(12)
                                            .shadow(radius: 4)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                if !qrCodes.isEmpty {
                    Divider()
                    Text("📡 Generated QR Codes")
                        .font(.headline)

                    ScrollView(.horizontal, showsIndicators: true) {
                        HStack(spacing: 20) {
                            ForEach(Array(qrCodes.enumerated()), id: \.offset) { idx, qr in
                                VStack {
                                    Text("QR \(idx+1)/\(qrCodes.count)")
                                        .font(.caption)
                                        .foregroundColor(.white)

                                    Image(uiImage: qrWithWhiteBackground(qr))
                                        .resizable()
                                        .interpolation(.none)
                                        .scaledToFit()
                                        .frame(width: 240, height: 240)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .shadow(radius: 4)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                
                }
                
                Divider()
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
        }
    }

    @MainActor
    private func handleScanned(code: String) async {
        scannedJSON = code
        statusMessage = "📄 QR scanned successfully. Loading compatible credentials..."

        do {
            guard let data = code.data(using: .utf8) else { return }

            let decoded = try JSONDecoder().decode(RequestPresentationMessageV2.self, from: data)
            let anonCredsProofString = try decoded.anoncredsProofRequest()

            guard let proofData = anonCredsProofString.data(using: .utf8) else { return }

            proofRequest = try JSONDecoder().decode(AnonCredsProofRequest.self, from: proofData)

            await loadAvailableCredentials()

            statusMessage = availableCredentials.isEmpty
                ? "No compatible credentials found."
                : "✅ \(availableCredentials.count) compatible credential(s) found."

        } catch {
            statusMessage = "❌ Error: \(error.localizedDescription)"
        }
    }

    private func loadAvailableCredentials() async {
        guard let proof = proofRequest else { return }
        guard let allRecords = await agent?.credentialExchangeRepository.getAll() else { return }

        let requestedCredDefIds = proof.requestedAttributes.values
            .compactMap { $0.restrictions?.compactMap { $0.credDefId } }
            .flatMap { $0 }

        let requestedAttrNames = proof.requestedAttributes.values
            .compactMap {
                $0.names ?? ($0.name != nil ? [$0.name!] : [])
            }
            .flatMap { $0 }

        let compatible = allRecords.compactMap { record -> CredentialInfo? in
            guard let recordCredDefId = record.credentialDefinitionId else { return nil }

            let attributesDict = Dictionary(
                uniqueKeysWithValues: (record.credentialAttributes ?? [])
                    .map { ($0.name, $0.value) }
            )

            let hasAllAttributes = requestedAttrNames.allSatisfy { attributesDict.keys.contains($0) }
            let matchesCredDef = requestedCredDefIds.isEmpty || requestedCredDefIds.contains(recordCredDefId)

            return (hasAllAttributes && matchesCredDef) ? CredentialInfo(
                id: record.id,
                attrs: attributesDict,
                schema_id: record.schemaId,
                type: record.credentials.map { $0.credentialRecordType },
                credentialDefinitionId: recordCredDefId,
                revRegId: record.revRegId ?? "",
                createdAt: record.createdAt
            ) : nil
        }

        await MainActor.run { availableCredentials = compatible }
    }

    private func generatePresentation() async {
        guard let code = scannedJSON else { return }
        guard let selectedCredentialId = selectedCredentialId else { return }

        isProcessing = true
        qrCodes = []

        do {
            let data = code.data(using: .utf8)!
            let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            let requestMsg = try JSONDecoder().decode(RequestPresentationMessageV2.self, from: jsonData)

            let record = try await agent!.proofCommandV2.processRequest(requestMessage: requestMsg)

            let (_, presentation) = try await agent!.proofCommandV2.createPresentation(
                record: record,
                chosenCredentialId: selectedCredentialId
            )

            presentationResult = presentation as? [String : Any]

            let encoder = JSONEncoder()
            encoder.outputFormatting = []
            let minifiedData = try encoder.encode(presentation)

            let jsonString = String(data: minifiedData, encoding: .utf8)!
            print("Presentation JSON size: \(jsonString.count) bytes")

            qrCodes = generateMultiQR(from: jsonString)

            print("Total generated QR codes: \(qrCodes.count)")
            statusMessage = "✅ Presentation successfully created!"

        } catch {
            statusMessage = "❌ Error: \(error.localizedDescription)"
        }

        isProcessing = false
    }

    private func prettyJSONString(from dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    

    func splitIntoQRChunks(_ base64: String, chunkSize: Int = 2000) -> [String] {
        var chunks: [String] = []
        var start = base64.startIndex

        while start < base64.endIndex {
            let end = base64.index(start, offsetBy: chunkSize, limitedBy: base64.endIndex) ?? base64.endIndex
            chunks.append(String(base64[start..<end]))
            start = end
        }

        let total = chunks.count
        return chunks.enumerated().map { "VP\($0+1)/\(total):" + $1 }
    }

    func generateMultiQR(from text: String, chunkSize: Int = 1500) -> [UIImage] {
        let total = Int(ceil(Double(text.count) / Double(chunkSize)))
        var images: [UIImage] = []

        for i in 0..<total {
            let start = text.index(text.startIndex, offsetBy: i * chunkSize, limitedBy: text.endIndex) ?? text.endIndex
            let end = text.index(start, offsetBy: chunkSize, limitedBy: text.endIndex) ?? text.endIndex
            let chunk = String(text[start..<end])

            let payload = "P\(i+1)/\(total)|" + chunk

            if let img = generateQRImage(from: payload) {
                images.append(img)
            }
        }

        return images
    }

    func generateQRImage(from text: String) -> UIImage? {
        guard let data = text.data(using: .utf8) else { return nil }

        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")

        let transform = CGAffineTransform(scaleX: 8, y: 8)
        guard let img = filter.outputImage?.transformed(by: transform) else { return nil }

        return UIImage(ciImage: img)
    }
    
    func qrWithWhiteBackground(_ image: UIImage) -> UIImage {
        let rect = CGRect(origin: .zero, size: image.size)

        UIGraphicsBeginImageContextWithOptions(image.size, true, 0)
        UIColor.white.setFill()
        UIRectFill(rect)
        image.draw(in: rect)

        let final = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return final!
    }
}
