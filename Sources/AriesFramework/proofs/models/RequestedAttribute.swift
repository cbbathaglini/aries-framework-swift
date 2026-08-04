
import Foundation

public struct RequestedAttribute {
    public let credentialId: String
    public let timestamp: Int?
    public let revealed: Bool
    public var credentialInfo: IndyCredentialInfo?
    public var revoked: Bool?
}

extension RequestedAttribute: Codable {
    enum CodingKeys: String, CodingKey {
        case credentialId = "cred_id", timestamp, revealed
    }

    mutating func setCredentialInfo(_ credentialInfo: IndyCredentialInfo) {
        self.credentialInfo = credentialInfo
    }
    
    public func toMap() -> [String: Any?] {
        return [
            "credentialId": self.credentialId,
            "schemaId": self.credentialInfo?.schemaId,
            "credentialDefinitionId": self.credentialInfo?.credentialDefinitionId,
            "attributes": self.credentialInfo?.attributes,
            "revoked": self.revoked
        ]
    }
}
