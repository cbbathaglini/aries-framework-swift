//
//  RetrievedCredentialsBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/26.
//

import Foundation
@testable import AriesFramework

final class RetrievedCredentialsBuilder {

    private var requestedAttributes: [String: [RequestedAttributeAnonCreds]] = [:]
    private var requestedPredicates: [String: [RequestedPredicateAnonCreds]] = [:]

    @discardableResult
    func setRequestedAttributes(_ value: [String: [RequestedAttributeAnonCreds]]) -> Self {
        self.requestedAttributes = value
        return self
    }

    @discardableResult
    func setRequestedPredicates(_ value: [String: [RequestedPredicateAnonCreds]]) -> Self {
        self.requestedPredicates = value
        return self
    }

    @discardableResult
    func addRequestedAttribute(
        referent: String,
        attribute: RequestedAttributeAnonCreds
    ) -> Self {
        self.requestedAttributes[referent, default: []].append(attribute)
        return self
    }

    @discardableResult
    func addRequestedPredicate(
        referent: String,
        predicate: RequestedPredicateAnonCreds
    ) -> Self {
        self.requestedPredicates[referent, default: []].append(predicate)
        return self
    }

    func buildAnonCreds() -> RetrievedCredentialsAnonCreds {
        RetrievedCredentialsAnonCreds(
            requestedAttributes: requestedAttributes,
            requestedPredicates: requestedPredicates
        )
    }
}
