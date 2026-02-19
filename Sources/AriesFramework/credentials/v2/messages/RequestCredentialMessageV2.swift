
import Foundation

public class RequestCredentialMessageV2: AgentMessage, CustomStringConvertible {
    public static let INDY_CREDENTIAL_REQUEST_ATTACHMENT_ID = "indy"
    public static let ANONCREDS_CREDENTIAL_REQUEST_ATTACHMENT_ID = "anoncreds"
    public static let type = CredentialConstants.requestCredentialV2

    public var formats: [Format]
    public var requestAttachments: [Attachment]
    public var attachments: [Attachment]
    public var goalCode: String?
    public var goal: String?
    public var comment: String?

    private enum CodingKeys: String, CodingKey {
        case formats
        case requestAttachments = "requests~attach"
        case attachments
        case goalCode = "goal_code"
        case goal
        case comment
    }

    public init(
        id: String? = nil,
        formats: [Format],
        attachments: [Attachment],
        requestAttachments: [Attachment],
        goalCode: String? = nil,
        goal: String? = nil,
        comment: String? = nil
    ) {
        self.formats = formats
        self.attachments = attachments
        self.requestAttachments = requestAttachments
        self.goalCode = goalCode
        self.goal = goal
        self.comment = comment
        super.init(id: id ?? UUID().uuidString, type: RequestCredentialMessageV2.type)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.formats = try container.decode([Format].self, forKey: .formats)
        self.requestAttachments = try container.decode([Attachment].self, forKey: .requestAttachments)
        self.attachments = try container.decode([Attachment].self, forKey: .attachments)
        self.goalCode = try container.decodeIfPresent(String.self, forKey: .goalCode)
        self.goal = try container.decodeIfPresent(String.self, forKey: .goal)
        self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(formats, forKey: .formats)
        try container.encode(requestAttachments, forKey: .requestAttachments)
        try container.encode(attachments, forKey: .attachments)
        try container.encodeIfPresent(goalCode, forKey: .goalCode)
        try container.encodeIfPresent(goal, forKey: .goal)
        try container.encodeIfPresent(comment, forKey: .comment)
        try super.encode(to: encoder)
    }

    public func getRequestAttachmentById(_ id: String) -> Attachment? {
        return requestAttachments.first { $0.id == id }
    }
    
    public var description: String {
        return """
        RequestCredentialMessageV2(
          id=\(self.id),
          formats=\(formats),
          requestAttachments=\(requestAttachments),
          attachments=\(attachments),
          goalCode=\(goalCode ?? "nil"),
          goal=\(goal ?? "nil"),
          comment=\(comment ?? "nil")
        )
        """
    }
}
