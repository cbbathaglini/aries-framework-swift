//
//  AnoncredsCredentialFormatTestFactory.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

enum AnoncredsCredentialFormatTestFactory {

    static func validCredentialFormats() -> [String: Any] {
        return [
            "anoncreds": [
                "schemaId": "schema:1",
                "schemaName": "Test Schema",
                "schemaVersion": "1.0",
                "schemaIssuerId": "issuer:1",
                "credentialDefinitionId": "creddef:1",
                "attributes": [
                    ["name": "name", "value": "Alice"],
                    ["name": "age", "value": "30"]
                ]
            ]
        ]
    }

    static func invalidCredentialFormats() -> [String: Any] {
        return [
            "anoncreds": [
                "schemaId": "" // inválido
            ]
        ]
    }
}
