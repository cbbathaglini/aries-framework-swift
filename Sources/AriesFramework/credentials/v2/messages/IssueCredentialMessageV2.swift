import Foundation

public class IssueCredentialMessageV2: AgentMessage, CustomStringConvertible {
    public static let INDY_CREDENTIAL_ATTACHMENT_ID = "indy"
    public static let ANONCREDS_CREDENTIAL_ATTACHMENT_ID = "anoncreds"
    public static let type = CredentialConstants.issueCredentialV2
    
    public var formats: [Format]
    public var credentialAttachments: [Attachment]
    public var goalCode: String?
    public var goal: String?
    public var comment: String?
    public var pleaseAck: AckDecorator?
    
    private enum CodingKeys: String, CodingKey {
        case formats
        case credentialAttachments = "credentials~attach"
        case goalCode = "goal_code"
        case goal
        case comment
        case pleaseAck
    }
    
    public init(
        id: String? = nil,
        formats: [Format],
        credentialAttachments: [Attachment],
        goalCode: String? = nil,
        goal: String? = nil,
        comment: String? = nil,
        pleaseAck: AckDecorator? = nil
    ) {
        self.formats = formats
        self.credentialAttachments = credentialAttachments
        self.goalCode = goalCode
        self.goal = goal
        self.comment = comment
        self.pleaseAck = pleaseAck
        super.init(id: id ?? UUID().uuidString, type: IssueCredentialMessageV2.type)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.formats = try container.decode([Format].self, forKey: .formats)
        self.credentialAttachments = try container.decode([Attachment].self, forKey: .credentialAttachments)
        self.goalCode = try container.decodeIfPresent(String.self, forKey: .goalCode)
        self.goal = try container.decodeIfPresent(String.self, forKey: .goal)
        self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        self.pleaseAck = try container.decodeIfPresent(AckDecorator.self, forKey: .pleaseAck)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(formats, forKey: .formats)
        try container.encode(credentialAttachments, forKey: .credentialAttachments)
        try container.encodeIfPresent(goalCode, forKey: .goalCode)
        try container.encodeIfPresent(goal, forKey: .goal)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encodeIfPresent(pleaseAck, forKey: .pleaseAck)
        try super.encode(to: encoder)
    }
    
    public func getCredentialAttachmentById(_ id: String) -> Attachment? {
        return credentialAttachments.first { $0.id == id }
    }
    
    public static func decode(from json: String) throws -> IssueCredentialMessageV2 {
        let data = json.data(using: .utf8)!
        return try JSONDecoder().decode(IssueCredentialMessageV2.self, from: data)
    }
    
    public func setPleaseAck(_ on: [AckValues] = [.receipt]) {
        self.pleaseAck = AckDecorator(on: on)
    }
 
    public var description: String {
        return """
        IssueCredentialMessageV2(
            formats: \(formats),
            credentialAttachments: \(credentialAttachments),
            goalCode: \(goalCode ?? "nil"),
            goal: \(goal ?? "nil"),
            comment: \(comment ?? "nil"),
            pleaseAck: \(pleaseAck?.description ?? "nil")
        )
        """
    }
    
}
