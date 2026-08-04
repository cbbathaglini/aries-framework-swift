
import Foundation

public struct RequestedPredicate {
    public let credentialId: String
    public let timestamp: Int?
    public var credentialInfo: IndyCredentialInfo?
    public var revoked: Bool?
}

extension RequestedPredicate: Codable {
    enum CodingKeys: String, CodingKey {
        case credentialId = "cred_id", timestamp
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
            "revoked": self.revoked,
            "predicateError": ""
        ]
    }
}
