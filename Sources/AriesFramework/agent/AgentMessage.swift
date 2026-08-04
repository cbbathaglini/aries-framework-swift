
import Foundation

public class AgentMessage: Codable {
    public var id: String
    public var type: String
    public var thread: ThreadDecorator?
    public var transport: TransportDecorator?

    var threadId: String {
        return thread?.threadId ?? id
    }

    private enum CodingKeys: String, CodingKey {
        case id = "@id", type = "@type", thread = "~thread", transport = "~transport"
    }

    public init(id: String? = nil, type: String) {
        self.id = id ?? UUID().uuidString
        self.type = type
    }

    public func setThread(threadId: String, parentThreadId: String? = nil) {
        self.thread = ThreadDecorator(threadId: threadId, parentThreadId: parentThreadId)
    }
    
    public func createOutboundMessage(connection: ConnectionRecord) -> OutboundMessage {
        return OutboundMessage(payload: self, connection: connection)
    }

    func requestResponse() -> Bool {
        return true
    }


    public static func generateId() -> String {
        return UUID().uuidString
    }

    open func toJsonString() throws -> String {
        let encoder = JSONEncoder()
        // swiftlint:disable:next force_try
        let data = try! encoder.encode(self)
        return String(data: data, encoding: .utf8)!
    }

    public func replaceNewDidCommPrefixWithLegacyDidSov() {
        self.type = Dispatcher.replaceNewDidCommPrefixWithLegacyDidSov(messageType: self.type)
    }
}
