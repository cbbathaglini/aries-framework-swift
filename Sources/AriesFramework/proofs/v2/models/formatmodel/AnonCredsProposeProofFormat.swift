//
//  AnonCredsProposeProofFormat.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

import Foundation

public struct AnonCredsProposeProofFormat: Codable {
    public var name: String?
    public var version: String?
    public var requestedAttributes: [String: AnonCredsPresentationPreviewAttribute]?
    public var requestedPredicates: [String: AnonCredsPresentationPreviewPredicate]?
    public var attributes: [AnonCredsPresentationPreviewAttribute]?
    public var predicates: [AnonCredsPresentationPreviewPredicate]?
    public var nonRevokedInterval: AnonCredsNonRevokedInterval?

    private enum CodingKeys: String, CodingKey {
        case name
        case version
        case requestedAttributes = "requested_attributes"
        case requestedPredicates = "requested_predicates"
        case attributes
        case predicates
        case nonRevokedInterval = "non_revoked"
    }

    public func normalizeFields() -> AnonCredsProposeProofFormat {
        return AnonCredsProposeProofFormat(
            name: self.name,
            version: self.version,
            requestedAttributes: self.requestedAttributes,
            requestedPredicates: self.requestedPredicates,
            attributes: self.requestedAttributes?.map { $0.value },
            predicates: self.requestedPredicates?.map { $0.value },
            nonRevokedInterval: self.nonRevokedInterval
        )
    }
}
