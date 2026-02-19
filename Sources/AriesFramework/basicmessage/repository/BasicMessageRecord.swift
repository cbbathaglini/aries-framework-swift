//
//  BasicMessageRecord.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 28/03/25.
//


import Foundation
import AnyCodable

public struct BasicMessageRecord: BaseRecord {
    public var id: String
    public var tags: Tags?
    public var createdAt: Date
    public var updatedAt: Date?
    public var content: String
    public var connectionRecord: ConnectionRecord?
    public var metadata: [String : AnyCodable] = [:]

    public static let type = "BasicMessageRecord"
}

extension BasicMessageRecord: Codable {
    enum CodingKeys: String, CodingKey {
        case id, tags, createdAt, updatedAt, metadata
        case content, connectionRecord
    }

    init(
        tags: Tags? = nil,
        updatedAt: Date? = nil,
        content: String,
        connectionRecord: ConnectionRecord? = nil
        ) {

        self.id = UUID().uuidString
        self.createdAt = Date()
        self.tags = tags
        self.updatedAt = updatedAt
        self.content = content
        self.connectionRecord = connectionRecord
    }

    public func getTags() -> Tags {
        var resultTags = tags ?? [:]
        if let connectionId = connectionRecord?.id {
            resultTags["connectionRecordId"] = connectionId
        }
        return resultTags
    }
    
    public func toMap() -> [String: Any?] {
        return [
            "id": self.id,
            "createdAt": String.fromDate(self.createdAt),
            "updatedAt" : String.fromDate(self.updatedAt),
            "content": self.content,
            "tags": self.tags,
            "connectionRecord": self.connectionRecord?.toMap() ?? nil,
            "metadata": self.metadata,
            "recordType": "BasicMessage",
        ]
    }
}

extension BasicMessageRecord: CustomStringConvertible {
    public var description: String {
        let connId = connectionRecord?.id ?? "nil"
        return "BasicMessageRecord(id=\"\(id)\", createdAt=\(createdAt), content=\"\(content)\", connectionRecord.id=\"\(connId)\")"
    }
}
