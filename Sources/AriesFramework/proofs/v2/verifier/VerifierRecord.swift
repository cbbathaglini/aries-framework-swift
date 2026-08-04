//
//  VerifierRecord.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/10/25.
//


import Foundation
import AnyCodable

public struct PresentationVerifier : Codable {
    public var presentationMessage: PresentationMessageV2? = nil 
    public var isVerified: Bool? = false
    public var isOffline: Bool? = true
    public var proofRecordId: String? = nil
}

public struct VerifierRecord: BaseRecord, Codable {
    public static let type = "VerifierRecord"
    public var id: String = UUID().uuidString
    public var createdAt: Date
    public var updatedAt: Date?
    public var tags: Tags?
    public var metadata: [String : AnyCodable] = [:]
    public var offline: Bool = false
    
    public var globalThreadId:String? = nil
    public var proofRequest: AnonCredsProofRequest? = nil // request proof
    public var requestMessage: RequestPresentationMessageV2? = nil // request proof
    public var presentation: [PresentationVerifier]? = []

    enum CodingKeys: String, CodingKey {
        case id, createdAt, updatedAt, tags, metadata
        case proofRequest, requestMessage, presentationMessage, globalThreadId, presentation
    }

    public init(
        id: String = UUID().uuidString,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        tags: Tags? = nil,
        metadata: [String: AnyCodable] = [:],
        proofRequest: AnonCredsProofRequest? = nil,
        requestMessage: RequestPresentationMessageV2? = nil,
        globalThreadId: String? = nil,
        offline: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        var newTags = tags ?? [:]
        
        if let globalThreadId = globalThreadId {
            newTags["globalThreadId"] = globalThreadId
        }
        self.tags = newTags
        self.metadata = metadata
        self.globalThreadId = globalThreadId
        self.proofRequest = proofRequest
        self.requestMessage = requestMessage
        self.offline = offline
    }

    public func getTags() -> Tags {
        var tags = self.tags ?? [:]
        if let globalThreadId = globalThreadId {
            tags["globalThreadId"] = globalThreadId
        }
        return tags
    }
    
    public mutating func addPresentation(
        _ newPresentation: PresentationVerifier,
        agent: Agent
    ) async {

        if presentation == nil {
            presentation = []
        }

        guard let proofRecordId = newPresentation.proofRecordId else {
            print("⚠️ Presentation not added. proofRecordId is nil")
            return
        }

        let query = """
        {
            "proofRecordId": "\(proofRecordId)"
        }
        """

        let records = await agent.verifierRepository.findByQuery(query)

        if !records.isEmpty {
            print("⚠️ Presentation not added. VerifierRecord already exists for proofId: \(proofRecordId)")
            return
        }

        presentation?.append(newPresentation)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        tags = try container.decodeIfPresent(Tags.self, forKey: .tags)
        metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata) ?? [:]
        
        globalThreadId = try container.decodeIfPresent(String.self, forKey: .globalThreadId)
        proofRequest = try container.decodeIfPresent(AnonCredsProofRequest.self, forKey: .proofRequest)
        requestMessage = try container.decodeIfPresent(RequestPresentationMessageV2.self, forKey: .requestMessage)
        presentation = try container.decodeIfPresent([PresentationVerifier].self, forKey: .presentation)
    }

    // MARK: - Custom Encoder
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encode(metadata, forKey: .metadata)
        
        try container.encodeIfPresent(globalThreadId, forKey: .globalThreadId)
        try container.encodeIfPresent(proofRequest, forKey: .proofRequest)
        try container.encodeIfPresent(requestMessage, forKey: .requestMessage)
        try container.encodeIfPresent(presentation, forKey: .presentation)
    }
    
    
    public func printDetails() {
        print("VerifierRecord Details:")
        print("ID: \(id)")
        print("Created At: \(createdAt)")
        print("Updated At: \(String(describing: updatedAt))")
        print("Global Thread ID: \(String(describing: globalThreadId))")
        print("Tags: \(String(describing: tags))")
        print("Metadata: \(metadata)")
        if let proofRequest = proofRequest {
            print("Proof Request Type: \(proofRequest)")
        } else {
            print("Proof Request: nil")
        }
        if let requestMessage = requestMessage {
            print("Request Message Type: \(requestMessage)")
        } else {
            print("Request Message: nil")
        }
        if let presentations = presentation {
            for (index, pres) in presentations.enumerated() {
                print("Presentation #\(index + 1):")
                print("  proofRecordId: \(String(describing: pres.proofRecordId))")
                print("  isVerified: \(String(describing: pres.isVerified))")
                print("  isOffline: \(String(describing: pres.isOffline))")
                print("  presentationMessage present: \(pres.presentationMessage != nil)")
            }
        } else {
            print("Presentations: nil")
        }
    }
}

