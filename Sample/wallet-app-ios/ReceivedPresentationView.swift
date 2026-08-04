//
//  ReceivedPresentationView.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 06/11/25.
//

import SwiftUI
import AriesFramework

struct ReceivedPresentationListView: View {
    @ObservedObject private var handler = VerifierHandler.shared
    @State private var isRefreshing = false

      
       var receivedRecords: [VerifierRecord] {
           handler.verifierRecords
               .sorted { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
       }

       var body: some View {
           NavigationView {
               List {
                   Section(header: headerView) {
                       if receivedRecords.isEmpty {
                           emptyStateView
                       } else {
                           ForEach(receivedRecords, id: \.id) { record in
                               NavigationLink(destination: ReceivedPresentationDetailView(record: record)) {
                                   recordCell(for: record)
                               }
                           }
                       }
                   }
               }
               .listStyle(.insetGrouped)
               .navigationTitle("Received")
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
                   }
               }
               .onAppear {
                   if handler.verifierRecords.isEmpty {
                       handler.refreshVerifierRecords()
                   }
               }
           }
       }

    // MARK: - Header
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

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(alignment: .center, spacing: 10) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 48))
                .foregroundColor(.gray)
                .padding(.top, 30)
            Text("No received presentations")
                .foregroundColor(.secondary)
                .font(.subheadline)
            Text("Presentations received via Bluetooth or QR will appear here.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Record Cell
    private func recordCell(for record: VerifierRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            
            HStack {
                Text("Thread ID:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(record.globalThreadId ?? "N/A")
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }

            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Presentations:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(record.presentation?.count ?? 0)")
                        .font(.subheadline)
                    Spacer()
                }

                
                Label {
                    Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                }
                
            }
        }
        .padding(.vertical, 6)
    }
    
    // MARK: - Refresh
    private func refreshRecords() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        handler.refreshVerifierRecords()
        try? await Task.sleep(nanoseconds: 800_000_000)
        withAnimation { isRefreshing = false }
    }
}
