//
//  RevocationNotificationMessage.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/25.
//

import Foundation

public class RevocationNotificationMessageV2: AgentMessage {
    public var revocationFormat: String
    public var credentialId: String
    public var comment: String?
    public var pleaseAck: AckDecorator?

    public static let type = RevocationNotificationConstants.typeMessageV2

    enum CodingKeys: String, CodingKey {
        case revocationFormat = "revocation_format"
        case credentialId = "credential_id"
        case comment
        case pleaseAck
    }

    public init(
        revocationFormat: String,
        credentialId: String,
        comment: String? = nil,
        pleaseAck: AckDecorator? = nil
    ) {
        self.revocationFormat = revocationFormat
        self.credentialId = credentialId
        self.comment = comment
        self.pleaseAck = pleaseAck
        super.init(id: UUID().uuidString, type: RevocationNotificationMessageV2.type)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.revocationFormat = try container.decode(String.self, forKey: .revocationFormat)
        self.credentialId = try container.decode(String.self, forKey: .credentialId)
        self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        self.pleaseAck = try container.decodeIfPresent(AckDecorator.self, forKey: .pleaseAck)
        super.init(id: UUID().uuidString, type: RevocationNotificationMessageV2.type)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(revocationFormat, forKey: .revocationFormat)
        try container.encode(credentialId, forKey: .credentialId)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encodeIfPresent(pleaseAck, forKey: .pleaseAck)
        try super.encode(to: encoder)
    }

    public func getThreadId(anonCredsRevocationRegistryId: String, anonCredsCredentialRevocationId: String) -> String {
        return "indy::\(anonCredsRevocationRegistryId)::\(anonCredsCredentialRevocationId)"
    }

    public func setPleaseAck(on: [AckValues] = [.receipt]) {
        self.pleaseAck = AckDecorator(on: on)
    }

    public func pleaseAckIsEmpty() -> Bool {
        return !(self.pleaseAck?.isNotEmpty() ?? false)
    }
}
