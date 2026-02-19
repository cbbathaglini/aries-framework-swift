//
//  BasicMessageInfos.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 27/03/25.
//

import Foundation

public class BasicMessageInfos: Codable {
    public var content: String
    public var createdAt: Date?
    public var theirLabel: String?
    public var connectionRecordId: String?

    enum CodingKeys: String, CodingKey {
        case content
        case createdAt
        case theirLabel
        case connectionRecordId
    }
    
    public init(
        content: String,
        createdAt: Date? = nil,
        theirLabel: String? = nil,
        connectionRecordId: String? = nil
    ) {
        self.content = content
        self.createdAt = createdAt
        self.theirLabel = theirLabel
        self.connectionRecordId = connectionRecordId
    
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.content = try container.decode(String.self, forKey: .content)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.theirLabel = try container.decodeIfPresent(String.self, forKey: .theirLabel)
        self.connectionRecordId = try container.decodeIfPresent(String.self, forKey: .connectionRecordId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(theirLabel, forKey: .theirLabel)
        try container.encodeIfPresent(connectionRecordId, forKey: .connectionRecordId)
    
    }
}
