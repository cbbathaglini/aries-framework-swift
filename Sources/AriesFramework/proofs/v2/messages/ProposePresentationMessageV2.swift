//
//  ProposePresentationMessageV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/10/25.
//

import Foundation

public class ProposePresentationMessageV2: AgentMessage {
    public var comment: String?
    public var goalCode: String?
    public var goal: String?
    public var proposalAttachments: [Attachment]
    public var formats: [ProofFormatSpec]

    public static let type = "https://didcomm.org/present-proof/2.0/propose-presentation"

    enum CodingKeys: String, CodingKey {
        case comment
        case goalCode = "goal_code"
        case goal
        case proposalAttachments = "proposals~attach"
        case formats
    }

    public init(
        comment: String? = nil,
        goalCode: String? = nil,
        goal: String? = nil,
        proposalAttachments: [Attachment] = [],
        formats: [ProofFormatSpec] = []
    ) {
        self.comment = comment
        self.goalCode = goalCode
        self.goal = goal
        self.proposalAttachments = proposalAttachments
        self.formats = formats
        super.init(id: UUID().uuidString, type: Self.type)
    }

    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        comment = try values.decodeIfPresent(String.self, forKey: .comment)
        goal = try values.decodeIfPresent(String.self, forKey: .goal)
        goalCode = try values.decodeIfPresent(String.self, forKey: .goalCode)
        formats = try values.decodeIfPresent([ProofFormatSpec].self, forKey: .formats) ?? []
        proposalAttachments = try values.decode([Attachment].self, forKey: .proposalAttachments)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encodeIfPresent(goal, forKey: .goal)
        try container.encodeIfPresent(goalCode, forKey: .goalCode)
        try container.encodeIfPresent(formats, forKey: .formats)
        try container.encode(proposalAttachments, forKey: .proposalAttachments)
        try super.encode(to: encoder)
    }
    
    public func getProposalAttachmentById(_ id: String) -> Attachment? {
        return proposalAttachments.first { $0.id == id }
    }
}
