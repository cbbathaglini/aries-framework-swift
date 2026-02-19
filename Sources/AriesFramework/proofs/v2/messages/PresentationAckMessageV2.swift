//
//  PresentationAckMessageV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 20/03/25.
//

import Foundation

public class PresentationAckMessageV2: AgentMessage, CustomStringConvertible {
    public static var type: String = "https://didcomm.org/present-proof/2.0/ack"
    var status: AckStatus

    private enum CodingKeys: String, CodingKey {
        case status
    }

    public init(id: String? = nil, threadId: String, status: AckStatus) {
        self.status = status
        super.init(id: id, type: PresentationAckMessageV2.type)
        self.thread = ThreadDecorator(threadId: threadId)
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        status = try values.decode(AckStatus.self, forKey: .status)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(status, forKey: .status)
        try super.encode(to: encoder)
    }

    override func requestResponse() -> Bool {
        return false
    }
    
    public var description: String {
        var parts: [String] = []
        parts.append("📩 PresentationAckMessageV2(id: \(id))")
        parts.append("  type: \(Self.type)")
        parts.append("  status: \(status.rawValue)")
        if let thread = thread {
            parts.append("  threadId: \(thread.threadId ?? "nil")")
        }
        return parts.joined(separator: "\n")
    }
}
