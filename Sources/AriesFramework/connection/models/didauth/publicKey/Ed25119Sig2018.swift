
import Foundation

public struct Ed25119Sig2018: Codable, PublicKey {
    public var id: String
    public var controller: String
    public var type: String = "Ed25519VerificationKey2018"
    public var publicKeyBase58: String
    public var value: String? {
        return publicKeyBase58
    }

    private enum CodingKeys: String, CodingKey {
        case id, controller, type, publicKeyBase58
    }
}
