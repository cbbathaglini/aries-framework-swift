
import Foundation
import AnyCodable

public struct ProofExchangeRecord: BaseRecord {
    public var id: String
    public var createdAt: Date
    public var updatedAt: Date?
    public var tags: Tags?
    public var metadata: [String : AnyCodable] = [:]

    public var connectionId: String
    public var threadId: String
    public var parentThreadId: String?
    public var isVerified: Bool?
    public var presentationId: String?
    public var state: ProofState
    public var role: ProofRole
    public var autoAcceptProof: AutoAcceptProof?
    public var errorMessage: String?
    public var comment:String?
    
    public var protocolVersion: String
    public var formats: [ProofFormatSpec]? = []
    
    public var proofRequestVerifierJson: String? = nil
    public var proofPresentationVerifierJson: String? = nil
    public var presentationMessage: PresentationMessageV2? = nil
    public var chosenCredentialId: String? = nil

    public static let type = "ProofRecord"
    public static let recordType = "ProofExchangeRecord"
}

extension ProofExchangeRecord: Codable {
    enum CodingKeys: String, CodingKey {
        case id, createdAt, updatedAt, tags, metadata
        case connectionId, threadId, parentThreadId, isVerified, presentationId, state, role, autoAcceptProof, errorMessage, formats, protocolVersion, presentationMessage, chosenCredentialId, comment
    }

    init(
        tags: Tags? = nil,
        connectionId: String,
        threadId: String,
        parentThreadId: String? = nil,
        isVerified: Bool? = nil,
        presentationId: String? = nil,
        state: ProofState,
        role: ProofRole,
        autoAcceptProof: AutoAcceptProof? = nil,
        errorMessage: String? = nil,
        protocolVersion: String,
        comment:String? = nil) {

        self.id = UUID().uuidString
        self.createdAt = Date()
        self.tags = tags
        self.connectionId = connectionId
        self.threadId = threadId
        self.parentThreadId = parentThreadId
        self.isVerified = isVerified
        self.presentationId = presentationId
        self.state = state
        self.role = role
        self.autoAcceptProof = autoAcceptProof
        self.errorMessage = errorMessage
        self.protocolVersion = protocolVersion
        self.comment = comment
        
    }

    public func getTags() -> Tags {
        var tags = self.tags ?? [:]

        tags["threadId"] = self.threadId
        tags["connectionId"] = self.connectionId
        tags["state"] = self.state.description
        tags["role"] = self.role.description

        return tags
    }

    public func assertState(_ expectedStates: ProofState...) throws {
        if !expectedStates.contains(self.state) {
            throw AriesFrameworkError.frameworkError(
                "Proof record is in invalid state \(self.state). Valid states are: \(expectedStates)"
            )
        }
    }

    public func assertConnection(_ currentConnectionId: String) throws {
        if self.connectionId != currentConnectionId {
            throw AriesFrameworkError.frameworkError(
                "Proof record is associated with connection '\(self.connectionId)'. Current connection is '\(currentConnectionId)'"
            )
        }
    }
    
    public func assertProtocolVersion(_ currentVersion: String) throws {
        if self.protocolVersion != currentVersion {
            throw AriesFrameworkError.frameworkError(
                "Proof record has invalid protocol version  '\(self.protocolVersion)'.  Expected version is '\(currentVersion)'"
            )
        }
    }
    
    public func toMap() -> [String: Any?] {
        return [
            "id": self.id,
            "createdAt": String.fromDate(self.createdAt),
            "updatedAt": String.fromDate(self.updatedAt),
            "connectionId": self.connectionId,
            "threadId": self.threadId,
            "parentThreadId": self.parentThreadId,
            "state": self.state.description,
            "role": self.role.description,
            "type": ProofExchangeRecord.type,
            "recordType": ProofExchangeRecord.recordType,
            "tags": self.tags,
            "metadata": self.metadata,
            "isVerified": self.isVerified,
            "presentationId": self.presentationId,
            "autoAcceptProof": self.autoAcceptProof?.description ?? nil,
            "errorMessage": self.errorMessage,
            "protocolVersion": self.protocolVersion,
            "comment": self.comment
        ]
    }
}
