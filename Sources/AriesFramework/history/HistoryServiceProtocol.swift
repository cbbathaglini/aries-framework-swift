//
//  HistoryServiceProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 16/03/26.
//

import Foundation

public protocol HistoryServiceProtocol: AnyObject {
    @discardableResult
    func save(
        historyType: HistoryType,
        connection: ConnectionRecord?,
        associatedRecordId id: String,
        content: String?,
        proofRequestedCredentialsAnoncreds: RequestedCredentialsAnoncreds?,
        credentials: [CredentialRecordBinding]?,
        credentialPreviewAttr: [CredentialPreviewAttribute]?,
        proofRequestedCredentials: RequestedCredentials?
    ) async throws -> HistoryRecord
}
