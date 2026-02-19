//
//  BluetoothClient.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 17/10/25.
//


import SwiftUI
import CoreBluetooth

enum BluetoothMode {
    case server
    case client
}

struct BluetoothView: View {
    @StateObject private var manager = BluetoothHandler()
    @State private var selectedMode: BluetoothMode = .server
    @State private var jsonInput: String = "{ \"proof\": \"example-data\" }"
    @State private var showCopied = false
    
    var body: some View {
        List {
            Section(header: Text("Modo de Operação")) {
                Picker("Modo", selection: $selectedMode) {
                    Text("Receber (Server)").tag(BluetoothMode.server)
                    Text("Enviar (Client)").tag(BluetoothMode.client)
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedMode) { newValue in
                    manager.switchMode(to: newValue)
                }
            }
            
            Section(header: Text("Status")) {
                HStack {
                    Text("Estado Bluetooth")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(manager.stateText)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Conectado a")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(manager.connectedDevice ?? "—")
                        .foregroundColor(.secondary)
                }
            }
            
            if selectedMode == .client {
                Section(header: Text("Enviar JSON")) {
                    TextEditor(text: $jsonInput)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 120)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                    
                    Button {
                        guard let data = jsonInput.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                        else {
                            manager.logMessage("❌ JSON inválido.")
                            return
                        }
                        manager.sendJSON(json)
                    } label: {
                        Label("Enviar JSON", systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!manager.isReadyToSend)
                }
            } else {
                Section(header: Text("Recebido")) {
                    if let receivedJSON = manager.receivedJSON {
                        ScrollView {
                            Text(receivedJSON)
                                .font(.system(.body, design: .monospaced))
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        Button {
                            UIPasteboard.general.string = receivedJSON
                            withAnimation {
                                showCopied = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation {
                                    showCopied = false
                                }
                            }
                        } label: {
                            Label("Copiar", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Text("Aguardando dados...")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Logs")) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(manager.logs, id: \.self) { log in
                            Text(log)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(minHeight: 120)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Bluetooth Transfer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            manager.switchMode(to: selectedMode)
        }
        .overlay(
            VStack {
                if showCopied {
                    Text("Copiado!")
                        .font(.caption)
                        .padding(8)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .transition(.opacity)
                        .animation(.easeInOut, value: showCopied)
                }
            }
            .padding(.bottom, 50),
            alignment: .bottom
        )
    }
}

#Preview {
    NavigationView {
        BluetoothView()
    }
}
