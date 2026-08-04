//
//  AnonCredsLinkSecretRecord.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//

import Foundation
import AnyCodable

public class AnonCredsLinkSecretRecord: BaseRecord, Codable {

    public static let type = "AnonCredsLinkSecretRecord"
    
    public var id: String
    public var tags: Tags?
    public var createdAt: Date
    public var updatedAt: Date?

    var linkSecretId: String
    var value: String?
    public var metadata: [String: AnyCodable] = [:]
    
    enum CodingKeys: String, CodingKey {
        case id, tags = "_tags", createdAt, updatedAt, metadata
        case linkSecretId, value
    }

    init(
        id: String = UUID().uuidString,
        tags: Tags? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        linkSecretId: String,
        value: String?
    ) {
        self.id = id
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.linkSecretId = linkSecretId
        self.value = value
    }

    func setTag(key: String, value: String?) {
        var newTags = tags ?? [:]
        if let value = value {
            newTags[key] = value
        } else {
            newTags.removeValue(forKey: key)
        }
        tags = newTags
    }

    public func getTags() -> Tags {
        var newTags = tags ?? [:]
        newTags["linkSecretId"] = linkSecretId
        return newTags
    }
}
