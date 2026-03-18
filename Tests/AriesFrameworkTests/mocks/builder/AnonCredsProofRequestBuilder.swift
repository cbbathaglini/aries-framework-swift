//
//  AnonCredsProofRequestBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/26.
//

import Foundation
@testable import AriesFramework

final class AnonCredsProofRequestBuilder {

    private var name: String = "proof-request"
    private var version: String = "1.0"
    private var nonce: String = "1234567890"
    private var requestedAttributes: [String: AnonCredsRequestedAttribute] = [:]
    private var requestedPredicates: [String: AnonCredsRequestedPredicate] = [:]
    private var nonRevoked: AnonCredsNonRevokedInterval? = nil
    private var ver: String? = nil

    @discardableResult
    func setName(_ value: String) -> Self {
        self.name = value
        return self
    }

    @discardableResult
    func setVersion(_ value: String) -> Self {
        self.version = value
        return self
    }

    @discardableResult
    func setNonce(_ value: String) -> Self {
        self.nonce = value
        return self
    }

    @discardableResult
    func setRequestedAttributes(_ value: [String: AnonCredsRequestedAttribute]) -> Self {
        self.requestedAttributes = value
        return self
    }

    @discardableResult
    func setRequestedPredicates(_ value: [String: AnonCredsRequestedPredicate]) -> Self {
        self.requestedPredicates = value
        return self
    }

    @discardableResult
    func setNonRevoked(_ value: AnonCredsNonRevokedInterval?) -> Self {
        self.nonRevoked = value
        return self
    }

    @discardableResult
    func setVer(_ value: String?) -> Self {
        self.ver = value
        return self
    }

    func build() -> AnonCredsProofRequest {
        AnonCredsProofRequest(
            name: name,
            version: version,
            nonce: nonce,
            requestedAttributes: requestedAttributes,
            requestedPredicates: requestedPredicates,
            nonRevoked: nonRevoked,
            ver: ver
        )
    }
}
