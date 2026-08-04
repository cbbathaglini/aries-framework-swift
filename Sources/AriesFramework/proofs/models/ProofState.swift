
import Foundation

public enum ProofState: String, Codable {
    case None = "none"
    case ProposalSent = "proposal-sent"
    case ProposalReceived = "proposal-received"
    case RequestSent = "request-sent"
    case RequestReceived = "request-received"
    case PresentationSent = "presentation-sent"
    case PresentationSentOffline = "presentation-sent-offline"
    case PresentationReceived = "presentation-received"
    case Declined = "declined"
    case Done = "done"
    case Abandoned = "abandoned"
    
    public var description: String {
        return self.rawValue
    }
}
