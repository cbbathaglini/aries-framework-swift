//
//  CredentialDetailView.swift
//  wallet-app-ios
//

import SwiftUI

struct CredentialDetailView: View {
    var credential: CredentialInfo
    @State private var copiedText: String? = nil

    var body: some View {
        List {
            Section(header: Text("Credential Information")) {

                if let state = credential.state {
                    HStack {
                        Text("Status")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(state.rawValue)
                            .foregroundColor(.secondary)
                    }
                }

                if let copiedText = copiedText {
                    Text(copiedText)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: copiedText)
                        .padding(.bottom, 30)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                
                HStack {
                    Text("ID")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(credential.id)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                    Button(action: {
                        copyToClipboard(credential.id)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                }
                
                HStack {
                    Text("W3C ID")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(credential.w3cId)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                    Button(action: {
                        copyToClipboard(credential.w3cId)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                }

                if let schemaId = credential.schema_id {
                    HStack {
                        Text("Schema ID")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(schemaId)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                if let credDefId = credential.credentialDefinitionId {
                    HStack {
                        Text("Credential Definition ID")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(credDefId)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }

                if let revReg = credential.revRegId {
                    HStack {
                        Text("Revocation Registry")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(revReg)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                if credential.isRevoked {
                    HStack {
                        Text("Is revoked?")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("true")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }


                if let types = credential.type, !types.isEmpty {
                    HStack(alignment: .top) {
                        Text("Type")
                            .fontWeight(.semibold)
                        Spacer()
                        VStack(alignment: .trailing) {
                            ForEach(types, id: \.self) { type in
                                Text(type)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

        
            Section(header: Text("Attributes")) {
                if credential.attrs.isEmpty {
                    Text("No attribute values are available yet. Accept the credential to view them.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(credential.attrs.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(key)
                                .font(.headline)
                            Text(value)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            
        }
        
        .navigationTitle("Credential Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        copiedText = "Copied!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copiedText = nil
        }
    }
}
