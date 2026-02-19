//
//  CreateProofOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation
import AnyCodable

public struct CreateProofOptions: Codable {
    public var requestMessage: RequestPresentationMessageV2
    public var proofRequest: AnonCredsProofRequest
    public var selectedCredentials: AnonCredsSelectedCredentials
    public var schemas: AnonCredsSchemas
    public var credentialDefinitions: AnonCredsCredentialDefinitions
    public var revocationRegistries: AnonCredsRevocationRegistries
    public var useUnqualifiedIdentifiers: Bool?
    public var proofFormats: [String: AnyCodable]?

    public init(
        requestMessage: RequestPresentationMessageV2,
        proofRequest: AnonCredsProofRequest,
        selectedCredentials: AnonCredsSelectedCredentials,
        schemas: AnonCredsSchemas,
        credentialDefinitions: AnonCredsCredentialDefinitions,
        revocationRegistries: AnonCredsRevocationRegistries,
        useUnqualifiedIdentifiers: Bool? = nil,
        proofFormats: [String: AnyCodable]? = [:]
    ) {
        self.requestMessage = requestMessage
        self.proofRequest = proofRequest
        self.selectedCredentials = selectedCredentials
        self.schemas = schemas
        self.credentialDefinitions = credentialDefinitions
        self.revocationRegistries = revocationRegistries
        self.useUnqualifiedIdentifiers = useUnqualifiedIdentifiers
        self.proofFormats = proofFormats
    }
}
