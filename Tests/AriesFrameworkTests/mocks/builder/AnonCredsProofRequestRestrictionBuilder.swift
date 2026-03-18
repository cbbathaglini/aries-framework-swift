//
//  AnonCredsProofRequestRestrictionBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/26.
//

import Foundation
@testable import AriesFramework

final class AnonCredsProofRequestRestrictionBuilder {

    private var schemaId: String? = nil
    private var schemaIssuerId: String? = nil
    private var schemaName: String? = nil
    private var schemaVersion: String? = nil
    private var issuerId: String? = nil
    private var credDefId: String? = nil
    private var revRegId: String? = nil
    private var schemaIssuerDid: String? = nil
    private var issuerDid: String? = nil
    private var attributeMarkers: [String: Bool] = [:]
    private var attributeValues: [String: String] = [:]

    @discardableResult
    func setSchemaId(_ value: String?) -> Self {
        self.schemaId = value
        return self
    }

    @discardableResult
    func setSchemaIssuerId(_ value: String?) -> Self {
        self.schemaIssuerId = value
        return self
    }

    @discardableResult
    func setSchemaName(_ value: String?) -> Self {
        self.schemaName = value
        return self
    }

    @discardableResult
    func setSchemaVersion(_ value: String?) -> Self {
        self.schemaVersion = value
        return self
    }

    @discardableResult
    func setIssuerId(_ value: String?) -> Self {
        self.issuerId = value
        return self
    }

    @discardableResult
    func setCredDefId(_ value: String?) -> Self {
        self.credDefId = value
        return self
    }

    @discardableResult
    func setRevRegId(_ value: String?) -> Self {
        self.revRegId = value
        return self
    }

    @discardableResult
    func setSchemaIssuerDid(_ value: String?) -> Self {
        self.schemaIssuerDid = value
        return self
    }

    @discardableResult
    func setIssuerDid(_ value: String?) -> Self {
        self.issuerDid = value
        return self
    }

    @discardableResult
    func setAttributeMarkers(_ value: [String: Bool]) -> Self {
        self.attributeMarkers = value
        return self
    }

    @discardableResult
    func setAttributeValues(_ value: [String: String]) -> Self {
        self.attributeValues = value
        return self
    }

    func build() -> AnonCredsProofRequestRestriction {
        AnonCredsProofRequestRestriction(
            schemaId: schemaId,
            schemaIssuerId: schemaIssuerId,
            schemaName: schemaName,
            schemaVersion: schemaVersion,
            issuerId: issuerId,
            credDefId: credDefId,
            revRegId: revRegId,
            schemaIssuerDid: schemaIssuerDid,
            issuerDid: issuerDid,
            attributeMarkers: attributeMarkers,
            attributeValues: attributeValues
        )
    }
}
