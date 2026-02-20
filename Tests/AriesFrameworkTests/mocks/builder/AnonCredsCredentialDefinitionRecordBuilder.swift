//
//  AnonCredsCredentialDefinitionRecordBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 20/02/26.
//

@testable import AriesFramework
import Foundation

final class AnonCredsCredentialDefinitionRecordBuilder {

    private var id: String = UUID().uuidString
    private var tags: Tags? = nil
    private var createdAt: Date = Date()
    private var updatedAt: Date? = nil

    private var credentialDefinitionId: String = "creddef:1"
    private var credentialDefinition: AnonCredsCredentialDefinition =
        AnonCredsCredentialDefinitionTestFactory.minimal()

    private var methodName: String = "test"

    func withCredentialDefinitionId(_ value: String) -> Self {
        credentialDefinitionId = value
        return self
    }

    func withCredentialDefinition(_ value: AnonCredsCredentialDefinition) -> Self {
        credentialDefinition = value
        return self
    }

    func withMethodName(_ value: String) -> Self {
        methodName = value
        return self
    }

    func withId(_ value: String) -> Self {
        id = value
        return self
    }

    func withCreatedAt(_ value: Date) -> Self {
        createdAt = value
        return self
    }

    func withUpdatedAt(_ value: Date?) -> Self {
        updatedAt = value
        return self
    }

    func withTags(_ value: Tags?) -> Self {
        tags = value
        return self
    }

    func build() -> AnonCredsCredentialDefinitionRecord {
        AnonCredsCredentialDefinitionRecord(
            id: id,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt,
            credentialDefinitionId: credentialDefinitionId,
            credentialDefinition: credentialDefinition,
            methodName: methodName
        )
    }
}
