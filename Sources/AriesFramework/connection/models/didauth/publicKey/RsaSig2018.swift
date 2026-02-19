
import Foundation

public struct RsaSig2018: Codable, PublicKey {
    public var id: String
    public var controller: String
    public var type: String = "RsaVerificationKey2018"
    public var publicKeyPem: String
    public var value: String? {
        return publicKeyPem
    }

    private enum CodingKeys: String, CodingKey {
        case id, controller, type, publicKeyPem
    }
}
