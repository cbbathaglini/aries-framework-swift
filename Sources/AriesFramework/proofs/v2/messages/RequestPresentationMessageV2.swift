//
//  RequestPresentationMessageV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 20/03/25.
//

import Foundation

public class RequestPresentationMessageV2: AgentMessage, CustomStringConvertible {
    public static let INDY_PROOF_REQUEST_ATTACHMENT_ID = "indy"
    public static let ANONCREDS_PROOF_REQUEST_ATTACHMENT_ID = "anoncreds"
    public static var type: String = "https://didcomm.org/present-proof/2.0/request-presentation"
    
    public var comment: String?
    public var goal: String?
    public var goalCode: String?
    public var willConfirm: Bool?
    public var presentMultiple: Bool?
    public var formats: [ProofFormatSpec]
    public var requestPresentationAttachments: [Attachment]
    
    private enum CodingKeys: String, CodingKey {
        case comment
        case goal
        case goalCode = "goal_code"
        case willConfirm = "will_confirm"
        case presentMultiple = "present_multiple"
        case formats
        case requestPresentationAttachments = "request_presentations~attach"
    }
    
    
    public init(
        id: String? = nil,
        comment: String? = nil,
        goal: String? = nil,
        goalCode: String? = nil,
        willConfirm: Bool? = true,
        presentMultiple: Bool? = false,
        formats: [ProofFormatSpec] = [],
        requestPresentationAttachments: [Attachment]
    ) {
        self.comment = comment
        self.goal = goal
        self.goalCode = goalCode
        self.willConfirm = willConfirm
        self.presentMultiple = presentMultiple
        self.formats = formats
        self.requestPresentationAttachments = requestPresentationAttachments
        super.init(id: id, type: RequestPresentationMessageV2.type)
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        comment = try values.decodeIfPresent(String.self, forKey: .comment)
        goal = try values.decodeIfPresent(String.self, forKey: .goal)
        goalCode = try values.decodeIfPresent(String.self, forKey: .goalCode)
        willConfirm = try values.decodeIfPresent(Bool.self, forKey: .willConfirm)
        presentMultiple = try values.decodeIfPresent(Bool.self, forKey: .presentMultiple)
        formats = try values.decodeIfPresent([ProofFormatSpec].self, forKey: .formats) ?? []
        requestPresentationAttachments = try values.decode([Attachment].self, forKey: .requestPresentationAttachments)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encodeIfPresent(goal, forKey: .goal)
        try container.encodeIfPresent(goalCode, forKey: .goalCode)
        try container.encodeIfPresent(willConfirm, forKey: .willConfirm)
        try container.encodeIfPresent(presentMultiple, forKey: .presentMultiple)
        try container.encodeIfPresent(formats, forKey: .formats)
        try container.encode(requestPresentationAttachments, forKey: .requestPresentationAttachments)
        try super.encode(to: encoder)
    }
    
    public func getRequestPresentationAttachmentById(_ id: String) -> Attachment? {
        return requestPresentationAttachments.first { $0.id == id }
    }
    
    public func indyProofRequest() throws -> String {
        guard let attachment = getRequestPresentationAttachmentById(Self.INDY_PROOF_REQUEST_ATTACHMENT_ID) else {
            throw AriesFrameworkError.frameworkError("Proof request attachment indy not found")
        }
        return try attachment.getDataAsString()
    }
    
    public func anoncredsProofRequest() throws -> String {
        guard let attachment = getRequestPresentationAttachmentById(Self.ANONCREDS_PROOF_REQUEST_ATTACHMENT_ID) else {
            throw AriesFrameworkError.frameworkError("Proof request attachment anoncreds not found")
        }
        return try attachment.getDataAsString()
    }
        
    public var description: String {
        return """
        RequestPresentationMessageV2(
            id: \(id),
            type: \(type),
            comment: \(comment ?? "nil"),
            goal: \(goal ?? "nil"),
            goalCode: \(goalCode ?? "nil"),
            willConfirm: \(willConfirm?.description ?? "nil"),
            presentMultiple: \(presentMultiple?.description ?? "nil"),
            formats: \(formats),
            requestPresentationAttachments: \(requestPresentationAttachments)
        )
        """
    }
}
