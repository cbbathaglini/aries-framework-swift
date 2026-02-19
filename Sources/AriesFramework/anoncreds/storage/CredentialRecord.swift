
import Foundation
import anoncreds_uniffi
import AnyCodable

public struct CredentialRecord: BaseRecord {
    public var id: String
    public var createdAt: Date
    public var updatedAt: Date?
    public var tags: Tags?
    public var metadata: [String : AnyCodable] = [:]

    public var credentialId: String
    public var credentialRevocationId: String?
    public var revocationRegistryId: String?
    public var linkSecretId: String
    public var credential: String
    public var schemaId: String
    public var schemaName: String
    public var schemaVersion: String
    public var schemaIssuerId: String
    public var issuerId: String
    public var credentialDefinitionId: String
    public var revocationNotification: RevocationNotification?

    public static let type = "CredentialRecord"
}

extension CredentialRecord: Codable {
    enum CodingKeys: String, CodingKey {
        case id, createdAt, updatedAt, tags, metadata
        case credentialId, credentialRevocationId, revocationRegistryId, linkSecretId, credential, schemaId, schemaName, schemaVersion, schemaIssuerId, issuerId, credentialDefinitionId
    }

    init(
        tags: Tags? = nil,
        credentialId: String,
        credentialRevocationId: String? = nil,
        revocationRegistryId: String? = nil,
        linkSecretId: String,
        credential: anoncreds_uniffi.Credential,
        schemaId: String,
        schemaName: String,
        schemaVersion: String,
        schemaIssuerId: String,
        issuerId: String,
        credentialDefinitionId: String,
        revocationNotification: RevocationNotification? = nil) {

        self.id = UUID().uuidString
        self.createdAt = Date()
        self.credentialId = credentialId
        self.credentialRevocationId = credentialRevocationId
        self.revocationRegistryId = revocationRegistryId
        self.linkSecretId = linkSecretId
        self.credential = credential.toJson()
        self.schemaId = schemaId
        self.schemaName = schemaName
        self.schemaVersion = schemaVersion
        self.schemaIssuerId = schemaIssuerId
        self.issuerId = issuerId
        self.credentialDefinitionId = credentialDefinitionId
        self.revocationNotification = revocationNotification

        self.tags = tags ?? [:]
        for (key, value) in credential.values() {
            self.tags!["attr::\(key)::value"] = value
            self.tags!["attr::\(key)::marker"] = "1"
        }
    }

    public func getTags() -> Tags {
        var tags = self.tags ?? [:]
        tags["credentialId"] = self.credentialId
        tags["credentialRevocationId"] = self.credentialRevocationId
        tags["revocationRegistryId"] = self.revocationRegistryId
        tags["linkSecretId"] = self.linkSecretId
        tags["schemaId"] = self.schemaId
        tags["schemaName"] = self.schemaName
        tags["schemaVersion"] = self.schemaVersion
        tags["schemaIssuerId"] = self.schemaIssuerId
        tags["issuerId"] = self.issuerId
        tags["credentialDefinitionId"] = self.credentialDefinitionId
        return tags
    }
    
    public func toCredentialExchangeRecord(
            connectionId: String,
            threadId: String,
            state: CredentialState,
            protocolVersion: String,
            role: CredentialRole? = nil
        ) -> CredentialExchangeRecord {
        
            
            return CredentialExchangeRecordBuilder()
                .setId(self.id)
                .setCreatedAt(self.createdAt)
                .setUpdatedAt(self.updatedAt)
                .setTags(self.tags)
                .setConnectionId(connectionId)
                .setThreadId(threadId)
                .setProtocolVersion(CredentialsConstants.PROTOCOL_VERSION_V2)
                .setState(state)
                .setRole(role)
                .setCredentials([CredentialRecordBinding(credentialRecordType: "indy", credentialRecordId: self.id)])
                .setRevocationNotification(self.revocationNotification)
                .setCredentialDefinitionId(self.credentialDefinitionId)
                .build()
        }
    
    public func parseCredential(credentialJson: String) -> [String: String] {
        guard !credentialJson.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return [:]
        }

        if let data = credentialJson.data(using: .utf8),
           let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
           let jsonDict = jsonObject as? [String: Any],
           let valuesNode = jsonDict["values"] as? [String: Any] {

            var result: [String: String] = [:]

            for (key, value) in valuesNode {
                if let valueObj = value as? [String: Any],
                   let rawValue = valueObj["raw"] as? String {
                    result[key] = rawValue
                } else {
                    result[key] = "N/A"
                }
            }

            return result
        }

        return [:]
    }
    
    public func toMap() -> [String: Any?] {
        return [
            "recordId": self.id,
            "credentialId": self.credentialId,
            "attributes": self.parseCredential(credentialJson: self.credential),
            "createdAt": String.fromDate(self.createdAt),
            "updatedAt": String.fromDate(self.updatedAt),
            "revocationId": self.credentialRevocationId,
            "linkSecretId": self.linkSecretId,
            "credential": self.credential,
            "schemaId": self.schemaId,
            "schemaName": self.schemaName,
            "schemaVersion": self.schemaVersion,
            "schemaIssuerId": self.schemaIssuerId,
            "issuerId": self.issuerId,
            "definitionId": self.credentialDefinitionId,
            "revocationRegistryId": self.revocationRegistryId,
            "revocationNotification": self.revocationNotification?.toMap() ?? nil
        ]
    }
}
