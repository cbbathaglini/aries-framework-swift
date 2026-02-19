//
//  RevocationNotificationMessageV1Options.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/25.
//
import Foundation

public struct RevocationNotificationMessageV1Options: Codable {
    public var issueThread: String
    public var id: String?
    public var comment: String?
    public var pleaseAck: AckDecorator?

    public init(
        issueThread: String,
        id: String? = nil,
        comment: String? = nil,
        pleaseAck: AckDecorator? = nil
    ) {
        self.issueThread = issueThread
        self.id = id
        self.comment = comment
        self.pleaseAck = pleaseAck
    }
}
