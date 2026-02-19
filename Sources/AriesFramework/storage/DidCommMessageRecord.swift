
import Foundation
import AnyCodable

public enum DidCommMessageRole: String, Codable {
    case Sender = "sender"
    case Receiver = "receiver"
    
    public var description: String {
        switch self {
        case .Sender:
            return "Sender"
        case .Receiver:
            return "Receiver"
        }
    }
}

public struct DidCommMessageRecord: BaseRecord {
    public var id: String
    public var createdAt: Date
    public var updatedAt: Date?
    public var tags: Tags?
    public var metadata: [String : AnyCodable] = [:]

    /// Agent message encoded as json string.
    public var message: String
    public var role: DidCommMessageRole
    public var associatedRecordId: String?

    public static let type = "DidCommMessageRecord"
}

extension DidCommMessageRecord: Codable {
    enum CodingKeys: String, CodingKey {
        case id, createdAt, updatedAt, tags, metadata
        case message, role, associatedRecordId
    }

    init(
        tags: Tags? = nil,
        message: AgentMessage,
        role: DidCommMessageRole,
        associatedRecordId: String? = nil) throws {

        self.id = DidCommMessageRecord.generateId()
        self.createdAt = Date()
        self.tags = tags
        self.message = try message.toJsonString()
        self.role = role
        self.associatedRecordId = associatedRecordId
    }

    public func getTags() -> Tags {
        var tags = self.tags ?? [:]

        if let agentMessage = try? JSONDecoder().decode(AgentMessage.self, from: message.data(using: .utf8)!) {
            tags["messageId"] = agentMessage.id
            tags["messageType"] = agentMessage.type
        }
        tags["role"] = self.role.rawValue
        tags["associatedRecordId"] = self.associatedRecordId

        return tags
    }
    
    public func toMap() -> [String: Any?] {
        return [
            "id": self.id,
            "tags": self.getTags(),
            "createdAt": String.fromDate(self.createdAt),
            "updatedAt": String.fromDate(self.updatedAt),
            "message": self.message,
            "role": self.role.description,
            "associatedRecordId": self.associatedRecordId,
            "metadata": self.metadata
        ]
    }
}
