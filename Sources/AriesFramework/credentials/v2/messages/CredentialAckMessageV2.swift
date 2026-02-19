
import Foundation

public class CredentialAckMessageV2: AgentMessage, CustomStringConvertible {
    public static let type: String = CredentialConstants.credentialAckV2
    public var status: AckStatus

    private enum CodingKeys: String, CodingKey {
        case status
    }

    public init(id: String? = nil, threadId: String, status: AckStatus) {
        self.status = status
        super.init(id: id ?? UUID().uuidString, type: CredentialAckMessageV2.type)
        self.thread = ThreadDecorator(threadId: threadId)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decode(AckStatus.self, forKey: .status)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(status, forKey: .status)
        try super.encode(to: encoder)
    }

    public override func requestResponse() -> Bool {
        return false
    }
    
    public var description: String {
        return "CredentialAckMessageV2(id: \(id), status: \(status), threadId: \(thread?.threadId ?? "nil"))"
    }
}
