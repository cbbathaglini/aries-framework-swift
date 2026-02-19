
import Foundation

public class OfferCredentialMessageV2: AgentMessage, CustomStringConvertible {
    public static let ANONCREDS_CREDENTIAL_OFFER_ATTACHMENT_ID = "anoncreds"
    public static let INDY_CREDENTIAL_OFFER_ATTACHMENT_ID = "indy"
    public static let type = CredentialConstants.offerCredentialV2

    public var formats: [Format]
    public var offerAttachments: [Attachment]
    public var goalCode: String?
    public var goal: String?
    public var comment: String?
    public var credentialPreview: CredentialPreviewV2?
    public var replacementId: String?

    private enum CodingKeys: String, CodingKey {
        case formats
        case offerAttachments = "offers~attach"
        case goalCode = "goal_code"
        case goal
        case comment
        case credentialPreview = "credential_preview"
        case replacementId = "replacement_id"
    }

    public init(
        id: String? = nil,
        formats: [Format],
        offerAttachments: [Attachment],
        goalCode: String? = nil,
        goal: String? = nil,
        comment: String? = nil,
        credentialPreview: CredentialPreviewV2? = nil,
        replacementId: String? = nil
    ) {
        self.formats = formats
        self.offerAttachments = offerAttachments
        self.goalCode = goalCode
        self.goal = goal
        self.comment = comment
        self.credentialPreview = credentialPreview
        self.replacementId = replacementId
        super.init(id: id ?? UUID().uuidString, type: OfferCredentialMessageV2.type)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.formats = try container.decode([Format].self, forKey: .formats)
        self.offerAttachments = try container.decode([Attachment].self, forKey: .offerAttachments)
        self.goalCode = try container.decodeIfPresent(String.self, forKey: .goalCode)
        self.goal = try container.decodeIfPresent(String.self, forKey: .goal)
        self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        self.credentialPreview = try container.decodeIfPresent(CredentialPreviewV2.self, forKey: .credentialPreview)
        self.replacementId = try container.decodeIfPresent(String.self, forKey: .replacementId)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(formats, forKey: .formats)
        try container.encode(offerAttachments, forKey: .offerAttachments)
        try container.encodeIfPresent(goalCode, forKey: .goalCode)
        try container.encodeIfPresent(goal, forKey: .goal)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encodeIfPresent(credentialPreview, forKey: .credentialPreview)
        try container.encodeIfPresent(replacementId, forKey: .replacementId)
        try super.encode(to: encoder)
    }

    public func findIndyFormatByAttachId() -> Format? {
        return formats.first { $0.attachId == OfferCredentialMessageV2.INDY_CREDENTIAL_OFFER_ATTACHMENT_ID }
    }
    
    public func findAnoncredsFormatByAttachId() -> Format? {
        return formats.first { $0.attachId == OfferCredentialMessageV2.ANONCREDS_CREDENTIAL_OFFER_ATTACHMENT_ID }
    }

    public func getOfferAttachmentById(_ id: String) -> Attachment? {
        return offerAttachments.first { $0.id == id }
    }

    public func getCredentialOffer() throws -> String {
        guard let attachment = getOfferAttachmentById(OfferCredentialMessageV2.INDY_CREDENTIAL_OFFER_ATTACHMENT_ID) else {
            throw CredoError("Credential offer attachment not found")
        }
        return try attachment.getDataAsString()
    }
    
    func getCredentialOfferAttach(_ attachId: String) throws -> String {
        guard let attachment = getOfferAttachmentById(attachId) else {
            throw NSError(domain: "OfferCredentialMessageV2", code: 0, userInfo: [NSLocalizedDescriptionKey: "Credential offer attachment not found"])
        }
        
        return try attachment.getDataAsString()
    }

    public func validateIndyAttachId() throws {
        guard findIndyFormatByAttachId() != nil else {
            throw CredoError("Indy attachment with id \(OfferCredentialMessageV2.INDY_CREDENTIAL_OFFER_ATTACHMENT_ID) not found in offer message")
        }
    }
    
    public func validateAnoncredsAttachId() throws {
        guard findAnoncredsFormatByAttachId() != nil else {
            throw CredoError("Anoncreds attachment with id \(OfferCredentialMessageV2.ANONCREDS_CREDENTIAL_OFFER_ATTACHMENT_ID) not found in offer message")
        }
    }

    public static func decode(from json: String) throws -> OfferCredentialMessageV2 {
        let data = json.data(using: .utf8)!
        return try JSONDecoder().decode(OfferCredentialMessageV2.self, from: data)
    }
    
    public var description: String {
        return """
        OfferCredentialMessageV2(
            type: \(Self.type),
            formats: \(formats),
            offerAttachments: \(offerAttachments),
            goalCode: \(goalCode ?? "nil"),
            goal: \(goal ?? "nil"),
            comment: \(comment ?? "nil"),
            credentialPreview: \(String(describing: credentialPreview)),
            replacementId: \(replacementId ?? "nil")
        )
        """
    }
}
