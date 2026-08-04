//
//  AnonCredsProofRequestRestriction.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct AnonCredsProofRequestRestriction: Codable {
    public var schemaId: String?
    public var schemaIssuerId: String?
    public var schemaName: String?
    public var schemaVersion: String?
    public var issuerId: String?
    public var credDefId: String?
    public var revRegId: String?

    public var schemaIssuerDid: String?
    public var issuerDid: String?

    public var attributeMarkers: [String: Bool] = [:]
    public var attributeValues: [String: String] = [:]

    enum CodingKeys: String, CodingKey {
        case schemaId = "schema_id"
        case schemaIssuerId = "schema_issuer_id"
        case schemaName = "schema_name"
        case schemaVersion = "schema_version"
        case issuerId = "issuer_id"
        case credDefId = "cred_def_id"
        case revRegId = "rev_reg_id"
        case schemaIssuerDid = "schema_issuer_did"
        case issuerDid = "issuer_did"
        case attributeMarkers
        case attributeValues
    }

    public init(
        schemaId: String? = nil,
        schemaIssuerId: String? = nil,
        schemaName: String? = nil,
        schemaVersion: String? = nil,
        issuerId: String? = nil,
        credDefId: String? = nil,
        revRegId: String? = nil,
        schemaIssuerDid: String? = nil,
        issuerDid: String? = nil,
        attributeMarkers: [String: Bool] = [:],
        attributeValues: [String: String] = [:]
    ) {
        self.schemaId = schemaId
        self.schemaIssuerId = schemaIssuerId
        self.schemaName = schemaName
        self.schemaVersion = schemaVersion
        self.issuerId = issuerId
        self.credDefId = credDefId
        self.revRegId = revRegId
        self.schemaIssuerDid = schemaIssuerDid
        self.issuerDid = issuerDid
        self.attributeMarkers = attributeMarkers
        self.attributeValues = attributeValues
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(schemaId, forKey: .schemaId)
        try container.encodeIfPresent(schemaIssuerId, forKey: .schemaIssuerId)
        try container.encodeIfPresent(schemaName, forKey: .schemaName)
        try container.encodeIfPresent(schemaVersion, forKey: .schemaVersion)
        try container.encodeIfPresent(issuerId, forKey: .issuerId)
        try container.encodeIfPresent(credDefId, forKey: .credDefId)
        try container.encodeIfPresent(revRegId, forKey: .revRegId)
        try container.encodeIfPresent(schemaIssuerDid, forKey: .schemaIssuerDid)
        try container.encodeIfPresent(issuerDid, forKey: .issuerDid)

        if !attributeMarkers.isEmpty {
            try container.encode(attributeMarkers, forKey: .attributeMarkers)
        }
        if !attributeValues.isEmpty {
            try container.encode(attributeValues, forKey: .attributeValues)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.schemaId = try container.decodeIfPresent(String.self, forKey: .schemaId)
        self.schemaIssuerId = try container.decodeIfPresent(String.self, forKey: .schemaIssuerId)
        self.schemaName = try container.decodeIfPresent(String.self, forKey: .schemaName)
        self.schemaVersion = try container.decodeIfPresent(String.self, forKey: .schemaVersion)
        self.issuerId = try container.decodeIfPresent(String.self, forKey: .issuerId)
        self.credDefId = try container.decodeIfPresent(String.self, forKey: .credDefId)
        self.revRegId = try container.decodeIfPresent(String.self, forKey: .revRegId)
        self.schemaIssuerDid = try container.decodeIfPresent(String.self, forKey: .schemaIssuerDid)
        self.issuerDid = try container.decodeIfPresent(String.self, forKey: .issuerDid)

        self.attributeMarkers = try container.decodeIfPresent([String: Bool].self, forKey: .attributeMarkers) ?? [:]
        self.attributeValues = try container.decodeIfPresent([String: String].self, forKey: .attributeValues) ?? [:]
    }
}
