
import Foundation

public enum AutoAcceptProof: String, Codable {
    case always = "always"

    /// Never auto accept a proof
    case never = "never"
    
    public var description: String {
        return rawValue
    }
}
