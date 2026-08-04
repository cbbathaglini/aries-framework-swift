
import Foundation

public class ProposeCredentialMessageV2: AgentMessage {
    public static let type = CredentialConstants.proposeCredentialV2

    public var formats: [Format]
    public var proposalAttachments: [Attachment]
    public var credentialPreview: CredentialPreviewV2?
    public var goalCode: String?
    public var goal: String?
    public var comment: String?

    private enum CodingKeys: String, CodingKey {
        case formats
        case proposalAttachments = "filters~attach"
        case credentialPreview = "credential_preview"
        case goalCode = "goal_code"
        case goal
        case comment
    }

    public init(
        id: String? = nil,
        formats: [Format],
        proposalAttachments: [Attachment],
        credentialPreview: CredentialPreviewV2? = nil,
        goalCode: String? = nil,
        goal: String? = nil,
        comment: String? = nil
    ) {
        self.formats = formats
        self.proposalAttachments = proposalAttachments
        self.credentialPreview = credentialPreview
        self.goalCode = goalCode
        self.goal = goal
        self.comment = comment
        super.init(id: id ?? UUID().uuidString, type: ProposeCredentialMessageV2.type)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.formats = try container.decode([Format].self, forKey: .formats)
        self.proposalAttachments = try container.decode([Attachment].self, forKey: .proposalAttachments)
        self.credentialPreview = try container.decodeIfPresent(CredentialPreviewV2.self, forKey: .credentialPreview)
        self.goalCode = try container.decodeIfPresent(String.self, forKey: .goalCode)
        self.goal = try container.decodeIfPresent(String.self, forKey: .goal)
        self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(formats, forKey: .formats)
        try container.encode(proposalAttachments, forKey: .proposalAttachments)
        try container.encodeIfPresent(credentialPreview, forKey: .credentialPreview)
        try container.encodeIfPresent(goalCode, forKey: .goalCode)
        try container.encodeIfPresent(goal, forKey: .goal)
        try container.encodeIfPresent(comment, forKey: .comment)
        try super.encode(to: encoder)
    }

    public func getProposalAttachmentById(_ id: String) -> Attachment? {
        return proposalAttachments.first { $0.id == id }
    }

    public class Builder {
        private var formats: [Format] = []
        private var proposalAttachments: [Attachment] = []
        private var credentialPreview: CredentialPreviewV2?
        private var goalCode: String?
        private var goal: String?
        private var comment: String?

        public func formats(_ formats: [Format]) -> Builder {
            self.formats = formats
            return self
        }

        public func proposalAttachments(_ proposalAttachments: [Attachment]) -> Builder {
            self.proposalAttachments = proposalAttachments
            return self
        }

        public func credentialPreview(_ credentialPreview: CredentialPreviewV2?) -> Builder {
            self.credentialPreview = credentialPreview
            return self
        }

        public func goalCode(_ goalCode: String?) -> Builder {
            self.goalCode = goalCode
            return self
        }

        public func goal(_ goal: String?) -> Builder {
            self.goal = goal
            return self
        }

        public func comment(_ comment: String?) -> Builder {
            self.comment = comment
            return self
        }

        public func build() -> ProposeCredentialMessageV2 {
            return ProposeCredentialMessageV2(
                formats: formats,
                proposalAttachments: proposalAttachments,
                credentialPreview: credentialPreview,
                goalCode: goalCode,
                goal: goal,
                comment: comment
            )
        }
    }
}
