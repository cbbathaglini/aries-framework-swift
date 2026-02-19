//
//  RequestProofViewConnectionLess.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 15/10/25.
//

import SwiftUI
import AriesFramework

struct RequestProofViewConnectionLess: View {
    let connectionId: String?
    
    @State private var attributes: [String] = ["nome"]
    @State private var predicates: [(name: String, operation: String, value: String)] = []

    @State private var newAttribute: String = ""
    @State private var newPredicateName: String = ""
    @State private var newPredicateOperation: String = ""
    @State private var newPredicateValue: String = ""

    @State private var credentialDefinitionId = ""
    @State private var credentialDefinitionIdPredicate: String = ""
    
    @State private var isLoading = false
    @State private var resultMessage: String?
    @State private var errorMessage: String?
    
    @State private var qrImage: UIImage?

    @StateObject private var proofHandler = ProofHandler.shared
    
    @State private var useInterval = false
    @State private var initialDatetime = Date()
    @State private var endDatetime = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
    
    init(connectionId: String? = nil) {
        self.connectionId = connectionId
    }
    
    private let operations = [
        PredicateType.GreaterThan.rawValue,
        PredicateType.LessThan.rawValue,
        PredicateType.GreaterThanOrEqualTo.rawValue,
        PredicateType.LessThanOrEqualTo.rawValue
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                Text("Proof Request")
                    .font(.title2)
                    .bold()

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Credential Definition ID")
                        .font(.headline)

                    TextField("Enter credentialDefinitionId", text: $credentialDefinitionId)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Requested Attributes")
                        .font(.headline)

                    HStack {
                        TextField("Attribute name", text: $newAttribute)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            guard !newAttribute.isEmpty else { return }
                            attributes.append(newAttribute)
                            newAttribute = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(attributes, id: \.self) { attr in
                        HStack {
                            Text(attr)
                            Spacer()
                            Button(role: .destructive) {
                                attributes.removeAll { $0 == attr }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }

                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Credential Definition ID (Predicates)")
                        .font(.headline)

                    TextField("Enter credentialDefinitionId", text: $credentialDefinitionIdPredicate)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Predicates")
                        .font(.headline)

                    HStack(spacing: 8) {
                        TextField("Predicate name", text: $newPredicateName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)

                        Picker("", selection: $newPredicateOperation) {
                            ForEach(operations, id: \.self) { op in
                                Text(op)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 60)

                        TextField("Value", text: $newPredicateValue)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)

                        Button {
                            guard !newPredicateName.isEmpty, !newPredicateValue.isEmpty else { return }
                            predicates.append(
                                (name: newPredicateName, operation: newPredicateOperation, value: newPredicateValue)
                            )
                            newPredicateName = ""
                            newPredicateValue = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(predicates.indices, id: \.self) { index in
                        let pred = predicates[index]
                        HStack {
                            Text("\(pred.name) \(pred.operation) \(pred.value)")
                            Spacer()
                            Button(role: .destructive) {
                                predicates.remove(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }

                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Include revocation time", isOn: $useInterval)

                    if useInterval {
                        DatePicker(
                            "",
                            selection: $endDatetime,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                Divider()

                // Status messages
                if isLoading {
                    ProgressView("Generating request...")
                        .padding()
                } else if let resultMessage = resultMessage {
                    Text(resultMessage)
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                Spacer()

                Button {
                    Task { await generateProofRequest() }
                } label: {
                    if let connectionId = connectionId, !connectionId.isEmpty {
                            Label("Send Proof Request", systemImage: "paperplane.fill")
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("Generate Proof Request", systemImage: "qrcode")
                                .frame(maxWidth: .infinity)
                        }
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 40)
                
                // QR Code
                if let qrImage = qrImage {
                    VStack(spacing: 10) {
                        Image(uiImage: qrImage)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 250, height: 250)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .shadow(radius: 4)
                        
                        Text("QR Code ready to scan")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Proof Request")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Generate Proof Request
    private func generateProofRequest() async {
        isLoading = true
        resultMessage = nil
        errorMessage = nil

        guard !attributes.isEmpty else {
            isLoading = false
            errorMessage = "You must add at least one attribute before generating a proof request."
            return
        }

        do {
            var deviceId: String = "Device_R" + UUID().uuidString
            if let idfv = UIDevice.current.identifierForVendor?.uuidString {
                deviceId = "Device_\(idfv)"
            }
            
            var proofRequest: [String: Any] = [
                "name": "Dynamic Proof Request",
                "comment": deviceId,
                "attributes": attributes.map { attr in
                    [
                        "names": [],
                        "credDefId": credentialDefinitionId,
                        "name": attr,
                        "schemaName": ""
                    ]
                },
                "predicates": predicates.map { pred in
                    [
                        "name": pred.name,
                        "type": pred.operation,
                        "value": pred.value,
                        "credDefId": credentialDefinitionIdPredicate,
                    ]
                }
            ]
            
            if useInterval {
                proofRequest["interval"] = [
                    "initial": UInt64(0),
                    "end": UInt64(toGMTTimestamp(endDatetime))
                ]
            }

            if let connId = connectionId, !connId.isEmpty {
                let result = try await proofHandler.generateProofRequest(
                    agent: agent!,
                    proofRequest: proofRequest,
                    type: "online",
                    connectionId: connId,
                )

                resultMessage = "✅ Proof request sent successfully!"

            } else {

                let result = try await proofHandler.generateProofRequest(
                    agent: agent!,
                    proofRequest: proofRequest,
                    type: "offline"
                )

                qrImage = result.qrImage
                resultMessage = "✅ Connectionless proof request ready!"
            }
           

        } catch {
            errorMessage = "❌ \(error.localizedDescription)"
        }

        isLoading = false
    }
    
    func toGMTTimestamp(_ date: Date) -> Int {
        let utc = TimeZone(secondsFromGMT: 0)!   // força GMT/UTC
        var calendar = Calendar.current
        calendar.timeZone = utc
        
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        
        let gmtDate = calendar.date(from: components)!
        return Int(gmtDate.timeIntervalSince1970)
    }
}

#Preview {
    RequestProofViewConnectionLess()
}
