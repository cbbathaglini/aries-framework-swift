//
//  RevocationNotificationMessage.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/25.
//

import Foundation

public class RevocationNotificationMessageV1: AgentMessage {
    public static let type = "https://didcomm.org/revocation_notification/1.0/revoke"

    public var issueThread: String
    public var comment: String?
    public var pleaseAck: AckDecorator?

    private enum CodingKeys: String, CodingKey {
        case issueThread = "thread_id"
        case comment
        case pleaseAck = "please_ack"
    }

    public init(
        id: String? = nil,
        issueThread: String,
        comment: String? = nil,
        pleaseAck: AckDecorator? = nil
    ) {
        self.issueThread = issueThread
        self.comment = comment
        self.pleaseAck = pleaseAck
        super.init(id: id ?? UUID().uuidString, type: RevocationNotificationMessageV1.type)
    }

    public convenience init(options: RevocationNotificationMessageV1Options) {
        self.init(
            issueThread: options.issueThread,
            comment: options.comment,
            pleaseAck: options.pleaseAck
        )
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        issueThread = try values.decode(String.self, forKey: .issueThread)
        comment = try values.decodeIfPresent(String.self, forKey: .comment)
        pleaseAck = try values.decodeIfPresent(AckDecorator.self, forKey: .pleaseAck)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(issueThread, forKey: .issueThread)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encodeIfPresent(pleaseAck, forKey: .pleaseAck)
        try super.encode(to: encoder)
    }
}
