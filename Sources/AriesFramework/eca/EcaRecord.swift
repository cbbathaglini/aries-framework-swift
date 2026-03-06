//
//  EcaRecords.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 05/03/26.
//

import Foundation
import AnyCodable

public struct EcaRecord: Codable, BaseRecord, CustomStringConvertible {
    public static let type = "EcaRecord"
    
    public var id: String
    public var tags: Tags? = nil
    public var createdAt: Date
    public var updatedAt: Date? = nil
    public var metadata: [String: AnyCodable] = [:]


    public var credentialText: String

    // MARK: - Coding
    enum CodingKeys: String, CodingKey {
        case id, tags, createdAt, updatedAt, metadata, credentialText
    }

    // MARK: - Init
    public init(
        id: String = UUID().uuidString,
        tags: Tags? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        metadata: [String: AnyCodable] = [:],
        credentialText: String
    ) {
        self.id = id
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.metadata = metadata
        self.credentialText = credentialText
    }

    // MARK: - BaseRecord requirements
    public func getTags() -> Tags {
        return tags ?? [:]
    }

    public mutating func addMetadata(key: String, value: AnyCodable) {
        metadata[key] = value
        updatedAt = Date()
    }

    public mutating func setTags(_ tags: Tags) {
        self.tags = tags
        updatedAt = Date()
    }

    // MARK: - CustomStringConvertible
    public var description: String {
        "EcaRecord(id=\(id), tags=\(tags ?? [:]), createdAt=\(createdAt), updatedAt=\(updatedAt?.description ?? "nil"), metadataKeys=\(metadata.keys), credentialTextCount=\(credentialText.count))"
    }
}
