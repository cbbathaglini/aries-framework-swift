//
//  AnonCredsProofRequest.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct AnonCredsProofRequest: Codable, CustomStringConvertible {
    public var name: String
    public var version: String
    public var nonce: String
    public var requestedAttributes: [String: AnonCredsRequestedAttribute]
    public var requestedPredicates: [String: AnonCredsRequestedPredicate]
    public var nonRevoked: AnonCredsNonRevokedInterval?
    public var ver: String?

    enum CodingKeys: String, CodingKey {
        case name, version, nonce, ver
        case requestedAttributes = "requested_attributes"
        case requestedPredicates = "requested_predicates"
        case nonRevoked = "non_revoked"
    }

    public init(
        name: String,
        version: String,
        nonce: String,
        requestedAttributes: [String: AnonCredsRequestedAttribute],
        requestedPredicates: [String: AnonCredsRequestedPredicate],
        nonRevoked: AnonCredsNonRevokedInterval? = nil,
        ver: String? = nil
    ) {
        self.name = name
        self.version = version
        self.nonce = nonce
        self.requestedAttributes = requestedAttributes
        self.requestedPredicates = requestedPredicates
        self.nonRevoked = nonRevoked
        self.ver = ver
    }

    public func toJson() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8)!
    }

    public var description: String {
        var components: [String] = []
        components.append("name: \(name)")
        components.append("version: \(version)")
        components.append("nonce: \(nonce)")
        components.append("requestedAttributes: \(requestedAttributes)")
        components.append("requestedPredicates: \(requestedPredicates)")
        if let nonRevoked = nonRevoked {
            components.append("nonRevoked: \(nonRevoked)")
        }
        if let ver = ver {
            components.append("ver: \(ver)")
        }
        return "AnonCredsProofRequest(\n  " + components.joined(separator: ",\n  ") + "\n)"
    }
}

extension AnonCredsProofRequest {
    func copyWith(nonce: String? = nil) -> AnonCredsProofRequest {
        return AnonCredsProofRequest(
            name: self.name,
            version: self.version,
            nonce: nonce ?? self.nonce,
            requestedAttributes: self.requestedAttributes,
            requestedPredicates: self.requestedPredicates,
            nonRevoked: self.nonRevoked,
            ver: self.ver
        )
    }
}

public enum RequestedItem {
    case attribute(AnonCredsRequestedAttribute)
    case predicate(AnonCredsRequestedPredicate)
}
