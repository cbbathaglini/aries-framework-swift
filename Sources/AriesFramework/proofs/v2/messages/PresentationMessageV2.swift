//
//  PresentationMessageV2.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 20/03/25.
//

import Foundation

public class PresentationMessageV2: AgentMessage, CustomStringConvertible {
    public var comment: String?
    public var goalCode: String?
    public var goal: String?
    public var lastPresentation: Bool?
    public var formats: [ProofFormatSpec]
    public var presentationAttachments: [Attachment]
    public var pleaseAck: AckDecorator?
    public var createdAt : Date

    public static let INDY_PROOF_ATTACHMENT_ID = "indy"
    public static let ANONCREDS_PROOF_ATTACHMENT_ID = "anoncreds"
    public static let type = "https://didcomm.org/present-proof/2.0/presentation"

    private enum CodingKeys: String, CodingKey {
        case comment,
             presentationAttachments = "presentations~attach",
             formats,
             goal,
             goalCode = "goal_code",
             lastPresentation = "last_presentation",
             pleaseAck,
             createdAt
    }

    public init(
            comment: String? = nil,
            goalCode: String? = nil,
            goal: String? = nil,
            lastPresentation: Bool? = true,
            formats: [ProofFormatSpec],
            presentationAttachments: [Attachment],
            pleaseAck: AckDecorator? = nil
    ) {
        self.comment = comment
        self.goalCode = goalCode
        self.goal = goal
        self.lastPresentation = lastPresentation
        self.formats = formats
        self.presentationAttachments = presentationAttachments
        self.pleaseAck = pleaseAck
        self.createdAt = Date()
        super.init(id: RecordUtils.generateId(), type: PresentationMessageV2.type)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        self.goal = try container.decodeIfPresent(String.self, forKey: .goal)
        self.goalCode = try container.decodeIfPresent(String.self, forKey: .goalCode)
        self.presentationAttachments = try container.decode([Attachment].self, forKey: .presentationAttachments)
        self.formats = try container.decode([ProofFormatSpec].self, forKey: .formats)
        self.lastPresentation = try container.decodeIfPresent(Bool.self, forKey: .lastPresentation)
        self.pleaseAck = try container.decodeIfPresent(AckDecorator.self, forKey: .pleaseAck)
        if let timestamp = try? container.decode(Double.self, forKey: .createdAt) {
            if timestamp > 10_000_000_000 {
                self.createdAt = Date(timeIntervalSince1970: timestamp / 1000)
            } else {
                self.createdAt = Date(timeIntervalSince1970: timestamp)
            }
        } else if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            // string ISO8601
            let isoFormatter = ISO8601DateFormatter()
            if let parsedDate = isoFormatter.date(from: dateString) {
                self.createdAt = parsedDate
            } else {
                self.createdAt = Date()
            }
        } else {
            self.createdAt = Date()
        }
        try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encodeIfPresent(goalCode, forKey: .goalCode)
        try container.encodeIfPresent(goal, forKey: .goal)
        try container.encodeIfPresent(lastPresentation, forKey: .lastPresentation)
        try container.encode(formats, forKey: .formats)
        try container.encode(presentationAttachments, forKey: .presentationAttachments)
        try container.encodeIfPresent(pleaseAck, forKey: .pleaseAck)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }
   
    public func getPresentationAttachmentById(_ id: String) -> Attachment? {
        return presentationAttachments.first { $0.id == id }
    }

    public func indyProof() throws -> String {
        guard let attachment = getPresentationAttachmentById(PresentationMessageV2.INDY_PROOF_ATTACHMENT_ID) else {
            throw AriesFrameworkError.frameworkError("Proof attachment not found")
        }
        return try attachment.getDataAsString()
    }
   

    public func anoncredsProof() throws -> String {
        guard let attachment = getPresentationAttachmentById(Self.ANONCREDS_PROOF_ATTACHMENT_ID) else {
            throw AriesFrameworkError.frameworkError("Presentation attachment not found")
        }
        return try attachment.getDataAsString()
    }

    public func setPleaseAck(_ on: [AckValues] = [.receipt]) {
        self.pleaseAck = AckDecorator(on: on)
    }
    
    public var description: String {
        var parts: [String] = []
        parts.append("🪶 PresentationMessageV2(id: \(id))")
        if let comment = comment { parts.append("  comment: \(comment)") }
        if let goalCode = goalCode { parts.append("  goalCode: \(goalCode)") }
        if let goal = goal { parts.append("  goal: \(goal)") }
        if let last = lastPresentation { parts.append("  lastPresentation: \(last)") }
        parts.append("  formats: \(formats.map { $0.description }.joined(separator: ", "))")
        parts.append("  attachments: \(presentationAttachments.map { $0.description }.joined(separator: ", "))")
        if let ack = pleaseAck { parts.append("  pleaseAck: \(ack)") }
        return parts.joined(separator: "\n")
    }

    override public func toJsonString() -> String {
        print("🔍 [PresentationMessageV2] toJsonString called")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(self)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 Full JSON:")
                print(jsonString)
                return jsonString
            } else {
                print("❌ Failed to convert data to String")
                return "{}"
            }
        } catch {
            print("❌ Error encoding PresentationMessageV2: \(error)")
            return "{}"
        }
    }
}
