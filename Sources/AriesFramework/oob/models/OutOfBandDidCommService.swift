
import Foundation

public enum OutOfBandDidCommService: Codable {
    case oobDidDocument(OutOfBandDidDocumentService)
    case did(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let did = try? container.decode(String.self) {
            self = .did(did)
        } else {
            self = .oobDidDocument(try container.decode(OutOfBandDidDocumentService.self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .oobDidDocument(let oobDidDocument):
            try oobDidDocument.encode(to: encoder)
        case .did(let did):
            try did.encode(to: encoder)
        }
    }

    public func asDidDocService() throws -> DidDocService? {
        switch self {
        case .oobDidDocument(let oobDidDocument):
            let service = DidCommService(
                id: oobDidDocument.id,
                serviceEndpoint: oobDidDocument.serviceEndpoint,
                recipientKeys: try DIDParser.ConvertDidKeysToVerkeys(didKeys: oobDidDocument.recipientKeys),
                routingKeys: try DIDParser.ConvertDidKeysToVerkeys(didKeys: oobDidDocument.routingKeys ?? []))
            return DidDocService.didComm(service)
        case .did:
            return nil
        }
    }
}

public struct OutOfBandDidDocumentService: Codable {
    public static let typeConst = "did-communication"

    public var id: String
    public var type: String = OutOfBandDidDocumentService.typeConst
    public var serviceEndpoint: String
    public var recipientKeys: [String]
    public var routingKeys: [String]?
    public var accept: [String]?

    private enum CodingKeys: String, CodingKey {
        case id, type, serviceEndpoint, recipientKeys, routingKeys, accept
    }

    public init(
        id: String,
        serviceEndpoint: String,
        recipientKeys: [String],
        routingKeys: [String]? = nil,
        accept: [String]? = nil,
        type: String = OutOfBandDidDocumentService.typeConst
    ) {
        self.id = id
        self.type = type
        self.serviceEndpoint = serviceEndpoint
        self.recipientKeys = recipientKeys
        self.routingKeys = routingKeys
        self.accept = accept
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(String.self, forKey: .id)
        serviceEndpoint = try c.decode(String.self, forKey: .serviceEndpoint)
        recipientKeys = try c.decode([String].self, forKey: .recipientKeys)
        routingKeys = try c.decodeIfPresent([String].self, forKey: .routingKeys)
        accept = try c.decodeIfPresent([String].self, forKey: .accept)

        // ✅ aqui está o fix:
        type = try c.decodeIfPresent(String.self, forKey: .type) ?? Self.typeConst
    }
}
