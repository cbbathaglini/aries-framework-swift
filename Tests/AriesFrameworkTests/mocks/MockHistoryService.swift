//
//  MockHistoryService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 16/03/26.
//

@testable import AriesFramework
import Foundation

final class MockHistoryService: HistoryServiceProtocol {

    private(set) var saveCalled = false
    private(set) var savedRecords: [HistoryRecord] = []

    var recordToReturn = HistoryRecordBuilder()
        .setHistoryType(.proofRequestReceived)
        .setConnectionId("conn-123")
        .setAssociatedRecordId("history-id")
        .build()

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
        saveCalled = true

        let record = HistoryRecordBuilder()
            .setHistoryType(historyType)
            .setConnectionId(connection?.id ?? "")
            .setAssociatedRecordId(id)
            .setContent(content)
            .setCredentials(credentials)
            .setCredentialPreviewAttr(credentialPreviewAttr)
            .setProofRequestedCredentials(proofRequestedCredentials)
            .setProofRequestedCredentialsAnoncreds(proofRequestedCredentialsAnoncreds)
            .build()

        savedRecords.append(record)
        return record
    }
}
