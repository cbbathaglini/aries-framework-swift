//
//  RevocationNotificationMessageV1Options.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/25.
//
import Foundation

public struct RevocationNotificationMessageV2Options: Codable {

    public var revocationFormat: String
    public var credentialId: String
    public var comment: String?
    public var pleaseAck: AckDecorator?
    
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
    }
}
