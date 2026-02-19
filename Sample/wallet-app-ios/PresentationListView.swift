//
//  PresentationListView.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 17/10/25.
//

import SwiftUI
import AriesFramework

struct PresentationListView: View {
    @ObservedObject private var handler = PresentationHandler.shared
    @State private var isRefreshing = false

    var filteredRecords: [ProofExchangeRecord] {
        handler.proofRecords
            .filter { $0.presentationMessage != nil }
            .sorted { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: headerView) {
                    if filteredRecords.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(filteredRecords, id: \.id) { record in
                            NavigationLink(destination: PresentationDetailView(record: record)) {
                                recordCell(for: record)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Presentations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await refreshRecords() }
                    } label: {
                        HStack(spacing: 4) {
                            if isRefreshing {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Refresh")
                                .font(.subheadline)
                        }
                    }
                    .accessibilityLabel("Refresh")
                }
            }
            .onAppear {
                if handler.proofRecords.isEmpty {
                    handler.refreshVerifierRecords()
                }
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Received Presentations")
                .font(.headline)
            if let last = handler.lastUpdated {
                Text("Last updated: \(last.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyStateView: some View {
        VStack(alignment: .center, spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.gray)
                .padding(.top, 30)
            Text("No presentations available")
                .foregroundColor(.secondary)
                .font(.subheadline)
            Text("Received presentations will appear here.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func recordCell(for record: ProofExchangeRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ID: \(record.id)")
                        .font(.headline)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider().opacity(0.1)

            HStack {
                if let created = record.createdAt as Date? {
                    Label(created.formatted(date: .abbreviated, time: .shortened),
                          systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if record.presentationMessage != nil {
                    Label("Ready", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Label("Pending", systemImage: "hourglass")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func refreshRecords() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        handler.refreshVerifierRecords()
        try? await Task.sleep(nanoseconds: 800_000_000)
        withAnimation { isRefreshing = false }
    }
}
