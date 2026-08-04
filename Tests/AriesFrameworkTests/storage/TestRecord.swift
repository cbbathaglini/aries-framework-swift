
import Foundation
import AnyCodable

@testable import AriesFramework

struct TestRecord: BaseRecord {
    var id: String
    var createdAt: Date = Date()
    var tags: Tags?
    var foo: String
    var metadata: [String : AnyCodable] = [:]

    public static let type = "TestRecord"
    var type: String {
        return TestRecord.type
    }
}

extension TestRecord: Codable {
    enum CodingKeys: String, CodingKey {
        case id, createdAt, tags, foo, metadata
    }

    init(id: String? = nil, createdAt: Date? = nil, tags: Tags? = nil, foo: String, metadata:[String : AnyCodable]=[:]) {
        self.id = id ?? UUID().uuidString
        self.createdAt = createdAt ?? Date()
        self.tags = tags ?? Tags()
        self.foo = foo
        self.metadata = metadata
    }

    func getTags() -> Tags {
        return self.tags ?? [:]
    }
}
