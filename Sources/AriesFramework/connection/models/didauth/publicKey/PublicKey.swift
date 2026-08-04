
import Foundation

public protocol PublicKey {
    var id: String { get }
    var controller: String { get }
    var type: String { get }
    var value: String? { get }
}

extension PublicKey {
    static public func toMap(_ publicKey: PublicKey) -> [String: Any?] {
        return [
            "id": publicKey.id,
            "controller": publicKey.controller,
            "value": publicKey.value
        ]
    }
}
