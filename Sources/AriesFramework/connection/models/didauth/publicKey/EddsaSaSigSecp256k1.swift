
import Foundation

public struct EddsaSaSigSecp256k1: Codable, PublicKey {
    public var id: String
    public var controller: String
    public var type: String = "Secp256k1VerificationKey2018"
    public var publicKeyHex: String
    public var value: String? {
        return publicKeyHex
    }

    private enum CodingKeys: String, CodingKey {
        case id, controller, type, publicKeyHex
    }
}
