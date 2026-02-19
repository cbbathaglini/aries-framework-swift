//
//  History.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 08/10/25.
//

import Foundation

final class HistoryService {
    private let historyRepository: HistoryRepository

    init(historyRepository: HistoryRepository) {
        self.historyRepository = historyRepository
    }

    @discardableResult
    func save(
        historyType: HistoryType,
        connection: ConnectionRecord?,
        associatedRecordId id: String,
        content: String? = nil,
        proofRequestedCredentialsAnoncreds: RequestedCredentialsAnoncreds? = nil,
        credentials: [CredentialRecordBinding]? = nil,
        credentialPreviewAttr: [CredentialPreviewAttribute]? = nil,
        proofRequestedCredentials: RequestedCredentials? = nil
    ) async throws -> HistoryRecord {
        let history = HistoryRecord(
            historyType: historyType,
            connectionId: connection?.id ?? "",
            associatedRecordId: id,
            theirLabel: connection?.theirLabel,
            content: content ?? "none content",
            credentials: credentials,
            credentialPreviewAttr: credentialPreviewAttr,
            proofRequestedCredentialsAnoncreds: proofRequestedCredentialsAnoncreds,
        )
        logDebug("saving historical: \(history.id)")
        try await historyRepository.save(history)
        return history
    }
}
