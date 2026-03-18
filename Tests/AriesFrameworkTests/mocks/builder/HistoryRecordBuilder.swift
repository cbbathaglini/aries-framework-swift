//
//  HistoryRecordBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 16/03/26.
//

import Foundation
@testable import AriesFramework

final class HistoryRecordBuilder {

    private var id: String = UUID().uuidString
    private var tags: [String: String]? = nil
    private var createdAt: Date = Date()
    private var updatedAt: Date? = nil

    private var historyType: HistoryType = .proofRequestReceived
    private var connectionId: String = "connection-id"
    private var associatedRecordId: String = "record-id"

    private var theirLabel: String? = nil
    private var content: String? = nil

    private var credentials: [CredentialRecordBinding]? = nil
    private var credentialPreviewAttr: [CredentialPreviewAttribute]? = nil

    private var proofRequestedCredentials: RequestedCredentials? = nil
    private var proofRequestedCredentialsAnoncreds: RequestedCredentialsAnoncreds? = nil

    // MARK: - Setters

    @discardableResult
    func setId(_ value: String) -> Self {
        self.id = value
        return self
    }

    @discardableResult
    func setTags(_ value: [String: String]?) -> Self {
        self.tags = value
        return self
    }

    @discardableResult
    func setCreatedAt(_ value: Date) -> Self {
        self.createdAt = value
        return self
    }

    @discardableResult
    func setUpdatedAt(_ value: Date?) -> Self {
        self.updatedAt = value
        return self
    }

    @discardableResult
    func setHistoryType(_ value: HistoryType) -> Self {
        self.historyType = value
        return self
    }

    @discardableResult
    func setConnectionId(_ value: String) -> Self {
        self.connectionId = value
        return self
    }

    @discardableResult
    func setAssociatedRecordId(_ value: String) -> Self {
        self.associatedRecordId = value
        return self
    }

    @discardableResult
    func setTheirLabel(_ value: String?) -> Self {
        self.theirLabel = value
        return self
    }

    @discardableResult
    func setContent(_ value: String?) -> Self {
        self.content = value
        return self
    }

    @discardableResult
    func setCredentials(_ value: [CredentialRecordBinding]?) -> Self {
        self.credentials = value
        return self
    }

    @discardableResult
    func setCredentialPreviewAttr(_ value: [CredentialPreviewAttribute]?) -> Self {
        self.credentialPreviewAttr = value
        return self
    }

    @discardableResult
    func setProofRequestedCredentials(_ value: RequestedCredentials?) -> Self {
        self.proofRequestedCredentials = value
        return self
    }

    @discardableResult
    func setProofRequestedCredentialsAnoncreds(_ value: RequestedCredentialsAnoncreds?) -> Self {
        self.proofRequestedCredentialsAnoncreds = value
        return self
    }

    // MARK: - Build

    func build() -> HistoryRecord {
        HistoryRecord(
            id: id,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt,
            historyType: historyType,
            connectionId: connectionId,
            associatedRecordId: associatedRecordId,
            theirLabel: theirLabel,
            content: content,
            credentials: credentials,
            credentialPreviewAttr: credentialPreviewAttr,
            proofRequestedCredentials: proofRequestedCredentials,
            proofRequestedCredentialsAnoncreds: proofRequestedCredentialsAnoncreds
        )
    }
}
