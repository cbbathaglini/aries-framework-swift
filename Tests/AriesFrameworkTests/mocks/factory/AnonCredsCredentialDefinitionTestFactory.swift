//
//  AnonCredsCredentialDefinitionTestFactory.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 20/02/26.
//

@testable import AriesFramework
import Foundation
import AnyCodable

enum AnonCredsCredentialDefinitionTestFactory {

    static func minimal(
        issuerId: String = "did:test",
        schemaId: String = "schema:1",
        tag: String = "default",
        type: String = "CL",
        primary: [String: AnyCodable] = [:],
        revocation: AnyCodable? = nil
    ) -> AnonCredsCredentialDefinition {

        let value = CredentialDefinitionValue()
        value.primary = primary
        value.revocation = revocation

        return AnonCredsCredentialDefinition(
            issuerId: issuerId,
            schemaId: schemaId,
            type: type,
            tag: tag,
            value: value
        )
    }
}
