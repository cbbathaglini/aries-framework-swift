//
//  AnonCredsCredentialInfoBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/26.
//

import Foundation
@testable import AriesFramework

final class AnonCredsCredentialInfoBuilder {

    private var credentialId: String = "cred-id"
    private var attributes: [String: String] = [:]
    private var schemaId: String = "schema-id"
    private var credentialDefinitionId: String = "cred-def-id"
    private var revocationRegistryId: String? = nil
    private var credentialRevocationId: String? = nil
    private var methodName: String = "mock-method"
    private var createdAt: Date = Date()
    private var updatedAt: Date = Date()
    private var linkSecretId: String = "mock-link-secret-id"

    @discardableResult
    func setCredentialId(_ value: String) -> Self {
        self.credentialId = value
        return self
    }

    @discardableResult
    func setAttributes(_ value: [String: String]) -> Self {
        self.attributes = value
        return self
    }

    @discardableResult
    func setSchemaId(_ value: String) -> Self {
        self.schemaId = value
        return self
    }

    @discardableResult
    func setCredentialDefinitionId(_ value: String) -> Self {
        self.credentialDefinitionId = value
        return self
    }

    @discardableResult
    func setRevocationRegistryId(_ value: String?) -> Self {
        self.revocationRegistryId = value
        return self
    }

    @discardableResult
    func setCredentialRevocationId(_ value: String?) -> Self {
        self.credentialRevocationId = value
        return self
    }

    @discardableResult
    func setMethodName(_ value: String) -> Self {
        self.methodName = value
        return self
    }

    @discardableResult
    func setCreatedAt(_ value: Date) -> Self {
        self.createdAt = value
        return self
    }

    @discardableResult
    func setUpdatedAt(_ value: Date) -> Self {
        self.updatedAt = value
        return self
    }

    @discardableResult
    func setLinkSecretId(_ value: String) -> Self {
        self.linkSecretId = value
        return self
    }

    func build() -> AnonCredsCredentialInfo {
        AnonCredsCredentialInfo(
            credentialId: credentialId,
            attributes: attributes,
            schemaId: schemaId,
            credentialDefinitionId: credentialDefinitionId,
            revocationRegistryId: revocationRegistryId,
            credentialRevocationId: credentialRevocationId,
            methodName: methodName,
            createdAt: createdAt,
            updatedAt: updatedAt,
            linkSecretId: linkSecretId
        )
    }
}
