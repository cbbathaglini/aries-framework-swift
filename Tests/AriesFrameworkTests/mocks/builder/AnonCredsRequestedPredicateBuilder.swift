//
//  AnonCredsRequestedPredicateBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/26.
//

import Foundation
@testable import AriesFramework

final class AnonCredsRequestedPredicateBuilder {

    private var name: String = "age"
    private var pType: PredicateType = .GreaterThanOrEqualTo
    private var pValue: Int64 = 18
    private var restrictions: [AnonCredsProofRequestRestriction]? = nil
    private var nonRevoked: AnonCredsNonRevokedInterval? = nil

    @discardableResult
    func setName(_ value: String) -> Self {
        self.name = value
        return self
    }

    @discardableResult
    func setPType(_ value: PredicateType) -> Self {
        self.pType = value
        return self
    }

    @discardableResult
    func setPValue(_ value: Int64) -> Self {
        self.pValue = value
        return self
    }

    @discardableResult
    func setRestrictions(_ value: [AnonCredsProofRequestRestriction]?) -> Self {
        self.restrictions = value
        return self
    }

    @discardableResult
    func setNonRevoked(_ value: AnonCredsNonRevokedInterval?) -> Self {
        self.nonRevoked = value
        return self
    }

    func build() -> AnonCredsRequestedPredicate {
        AnonCredsRequestedPredicate(
            name: name,
            pType: pType,
            pValue: pValue,
            restrictions: restrictions,
            nonRevoked: nonRevoked
        )
    }
}
