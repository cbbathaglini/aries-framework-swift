//
// PresentationDetailView.swift
// wallet-app-ios
//

import SwiftUI
import AriesFramework

struct PresentationDetailView: View {
    
    let record: ProofExchangeRecord

    @State private var jsonPreview = ""
    @State private var status = ""

    private let hotspotServer = "192.0.0.1" //iphone

    var body: some View {
        List {
            Section(header: Text("Presentation Info")) {
                Text("Record ID: \(record.id)")
                if let createdAt = record.createdAt as Date? {
                    Text("Created at: " +
                        createdAt.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )
                }
            }

            Section(header: Text("Presentation JSON")) {
                ScrollView {
                    Text(jsonPreview)
                        .font(.system(.body, design: .monospaced))
                }
                .frame(maxHeight: 260)

                Button {
                    UIPasteboard.general.string = jsonPreview
                } label: {
                    Label("Copy JSON", systemImage: "doc.on.doc")
                }
            }

            Section(header: Text("Send to Hotspot")) {

                Text("Target: iPhone hotspot\nIP: 192.0.0.1:8080")
                    .foregroundColor(.secondary)

                Button {
                    
                } label: {
                    Label("Send Presentation", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if !status.isEmpty {
                    Text(status)
                        .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            loadJSON()
        }
    }


    private func loadJSON() {
        guard let p = record.presentationMessage else { return }

        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]

        if let data = try? enc.encode(p),
           let json = String(data: data, encoding: .utf8) {
            jsonPreview = json
        }
    }
}
