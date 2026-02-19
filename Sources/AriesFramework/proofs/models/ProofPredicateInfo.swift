
import Foundation

public struct ProofPredicateInfo {
    public let name: String
    public let nonRevoked: RevocationInterval?
    public let predicateType: PredicateType
    public let predicateValue: Int
    public let restrictions: [AttributeFilter]?
    
    public init(name: String, nonRevoked: RevocationInterval?, predicateType: PredicateType, predicateValue: Int, restrictions: [AttributeFilter]?) {
        self.name = name
        self.nonRevoked = nonRevoked
        self.predicateType = predicateType
        self.predicateValue = predicateValue
        self.restrictions = restrictions
    }
}

extension ProofPredicateInfo: Codable {
    private enum CodingKeys: String, CodingKey {
        case name, nonRevoked = "non_revoked", restrictions, predicateType = "p_type", predicateValue = "p_value"
    }

    func asProofAttributeInfo() -> ProofAttributeInfo {
        return ProofAttributeInfo(name: name, names: nil, nonRevoked: nonRevoked, restrictions: restrictions)
    }
}
