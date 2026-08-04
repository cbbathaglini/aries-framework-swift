
import Foundation

public enum ConnectionRole: String, Codable {
    case Inviter = "inviter"
    case Invitee = "invitee"
    
    public var description: String {
        switch self {
        case .Inviter:
            return "Inviter"
        case .Invitee:
            return "Invitee"
        }
    }
}

public enum ConnectionState: String, Codable {
    case Invited = "invited"
    case Requested = "requested"
    case Responded = "responded"
    case Complete = "complete"
    
    public var description: String {
        switch self {
        case .Invited:
            return "Invited"
        case .Requested:
            return "Requested"
        case .Responded:
            return "Responded"
        case .Complete:
            return "Complete"
        }
    }
}

public struct Connection: Codable {
    let did: String
    let didDoc: DidDoc?

    enum CodingKeys: String, CodingKey {
        case did = "DID"
        case didDoc = "DIDDoc"
        
        public var description: String {
            return rawValue
        }
    }
}
