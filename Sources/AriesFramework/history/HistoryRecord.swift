//
//  HistoryRecord.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 01/10/25.
//

import Foundation
import AnyCodable
public struct HistoryRecord: Codable, BaseRecord, CustomStringConvertible {
    public static let type = "HistoryRecord"

    public var id: String = UUID().uuidString
    public var tags: [String: String]? = nil
    public var createdAt: Date = Date()
    public var updatedAt: Date? = nil
    public var metadata: [String : AnyCodable] = [:]
    
    public var historyType: HistoryType
    public var connectionId: String
    public var associatedRecordId: String
    public var theirLabel: String? = nil
    public var content: String? = nil
    public var credentials: [CredentialRecordBinding]? = nil
    public var credentialPreviewAttr: [CredentialPreviewAttribute]? = nil
    public var proofRequestedCredentials: RequestedCredentials? = nil
    public var proofRequestedCredentialsAnoncreds: RequestedCredentialsAnoncreds? = nil

    
    enum CodingKeys: String, CodingKey {
        case id, tags, createdAt, updatedAt
        case historyType, connectionId, associatedRecordId, theirLabel, content, credentials, credentialPreviewAttr, proofRequestedCredentials, proofRequestedCredentialsAnoncreds
    }
    
    public init(
        id: String = UUID().uuidString,
        tags: [String: String]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        historyType: HistoryType,
        connectionId: String,
        associatedRecordId: String,
        theirLabel: String? = nil,
        content: String? = nil,
        credentials: [CredentialRecordBinding]? = nil,
        credentialPreviewAttr: [CredentialPreviewAttribute]? = nil,
        proofRequestedCredentials: RequestedCredentials? = nil,
        proofRequestedCredentialsAnoncreds: RequestedCredentialsAnoncreds? = nil
    ) {
        self.id = id
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.historyType = historyType
        self.connectionId = connectionId
        self.associatedRecordId = associatedRecordId
        self.theirLabel = theirLabel
        self.content = content
        self.credentials = credentials
        self.credentialPreviewAttr = credentialPreviewAttr
        self.proofRequestedCredentials = proofRequestedCredentials
        self.proofRequestedCredentialsAnoncreds = proofRequestedCredentialsAnoncreds
    }

    public var description: String {
        return """
        HistoryRecord(
            id: "\(id)",
            tags: \(tags ?? [:]),
            createdAt: \(createdAt),
            updatedAt: \(String(describing: updatedAt)),
            historyType: "\(historyType)",
            connectionId: "\(connectionId)",
            associatedRecordId: "\(associatedRecordId)",
            theirLabel: \(theirLabel ?? "nil"),
            content: \(content ?? "nil"),
            credentials: \(String(describing: credentials)),
            credentialPreviewAttr: \(String(describing: credentialPreviewAttr)),
            proofRequestedCredentials: \(String(describing: proofRequestedCredentials)),
            proofRequestedCredentialsAnoncreds: \(String(describing: proofRequestedCredentialsAnoncreds))
        )
        """
    }

    public func getTags() -> [String: String] {
        var resultTags = tags ?? [:]

        resultTags["historyType"] = historyType.rawValue
        resultTags["connectionId"] = connectionId
        resultTags["associatedRecordId"] = associatedRecordId

        if let proof = proofRequestedCredentials {
            for (_, attr) in proof.requestedAttributes {
                resultTags["credIdAttr:\(attr.credentialId)"] = "true"
            }
            for (_, pred) in proof.requestedPredicates {
                resultTags["credIdPred:\(pred.credentialId)"] = "true"
            }
        }

        if let anoncreds = proofRequestedCredentialsAnoncreds {
            for (_, attr) in anoncreds.requestedAttributes {
                resultTags["credIdAttr:\(attr.credentialId)"] = "true"
            }
            for (_, pred) in anoncreds.requestedPredicates {
                resultTags["credIdPred:\(pred.credentialId)"] = "true"
            }
        }

        if let creds = credentials {
            for credential in creds {
                resultTags["credRecordId:\(credential.credentialRecordId)"] = "true"
            }
        }

        return resultTags
    }
}
