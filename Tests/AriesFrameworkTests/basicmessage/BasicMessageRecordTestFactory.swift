//
//  BasicMessageRecordTestFactory.swift.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

import Foundation
import AnyCodable
@testable import AriesFramework

enum BasicMessageRecordTestFactory {

    static func minimal(
        content: String = "Hello world"
    ) -> BasicMessageRecord {
        return BasicMessageRecord(
            content: content
        )
    }

    static func withConnection(
        content: String = "Hello world",
        connection: ConnectionRecord
    ) -> BasicMessageRecord {
        return BasicMessageRecord(
            content: content,
            connectionRecord: connection
        )
    }

    static func withTags(
        content: String = "Hello world",
        tags: Tags
    ) -> BasicMessageRecord {
        return BasicMessageRecord(
            tags: tags,
            content: content
        )
    }

    static func complete(
        id: String = UUID().uuidString,
        content: String = "Hello world",
        connection: ConnectionRecord? = nil,
        tags: Tags? = nil,
        metadata: [String: AnyCodable] = [:],
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) -> BasicMessageRecord {

        var record = BasicMessageRecord(
            tags: tags,
            updatedAt: updatedAt,
            content: content,
            connectionRecord: connection
        )

        record.id = id
        record.metadata = metadata

        return record
    }
}
