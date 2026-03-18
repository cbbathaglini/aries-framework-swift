//
//  AnonCredsRequestedAttributeBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/26.
//

import Foundation
@testable import AriesFramework

final class AnonCredsRequestedAttributeBuilder {

    private var name: String? = "name"
    private var names: [String]? = nil
    private var nonRevoked: AnonCredsNonRevokedInterval? = nil
    private var restrictions: [AnonCredsProofRequestRestriction]? = nil

    @discardableResult
    func setName(_ value: String?) -> Self {
        self.name = value
        return self
    }

    @discardableResult
    func setNames(_ value: [String]?) -> Self {
        self.names = value
        return self
    }

    @discardableResult
    func setNonRevoked(_ value: AnonCredsNonRevokedInterval?) -> Self {
        self.nonRevoked = value
        return self
    }

    @discardableResult
    func setRestrictions(_ value: [AnonCredsProofRequestRestriction]?) -> Self {
        self.restrictions = value
        return self
    }

    func build() -> AnonCredsRequestedAttribute {
        AnonCredsRequestedAttribute(
            name: name,
            names: names,
            restrictions: restrictions,
            nonRevoked: nonRevoked,
        )
    }
}
