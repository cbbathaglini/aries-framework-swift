//
//  RequestedCredentialsBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/26.
//

import Foundation
@testable import AriesFramework

final class RequestedCredentialsBuilder {

    private var requestedAttributes: [String: RequestedAttributeAnonCreds] = [:]
    private var requestedPredicates: [String: RequestedPredicateAnonCreds] = [:]
    private var selfAttestedAttributes: [String: String] = [:]

    @discardableResult
    func setRequestedAttributes(_ value: [String: RequestedAttributeAnonCreds]) -> Self {
        self.requestedAttributes = value
        return self
    }

    @discardableResult
    func setRequestedPredicates(_ value: [String: RequestedPredicateAnonCreds]) -> Self {
        self.requestedPredicates = value
        return self
    }

    @discardableResult
    func setSelfAttestedAttributes(_ value: [String: String]) -> Self {
        self.selfAttestedAttributes = value
        return self
    }

    @discardableResult
    func addRequestedAttribute(
        referent: String,
        attribute: RequestedAttributeAnonCreds
    ) -> Self {
        self.requestedAttributes[referent] = attribute
        return self
    }

    @discardableResult
    func addRequestedPredicate(
        referent: String,
        predicate: RequestedPredicateAnonCreds
    ) -> Self {
        self.requestedPredicates[referent] = predicate
        return self
    }

    @discardableResult
    func addSelfAttestedAttribute(
        referent: String,
        value: String
    ) -> Self {
        self.selfAttestedAttributes[referent] = value
        return self
    }

    func build() -> RequestedCredentialsAnoncreds {
        RequestedCredentialsAnoncreds(
            requestedAttributes: requestedAttributes,
            requestedPredicates: requestedPredicates,
            selfAttestedAttributes: selfAttestedAttributes
        )
    }
}
