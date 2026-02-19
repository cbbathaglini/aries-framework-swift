//
//  CreateCredentialRequestReturn.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct CreateCredentialRequestReturn: Codable, CustomStringConvertible {
    public let credentialRequest: AnonCredsCredentialRequest
    public let credentialRequestMetadata: AnonCredsCredentialRequestMetadata

    public var description: String {
        return """
        CreateCredentialRequestReturn(
            credentialRequest: \(credentialRequest),
            credentialRequestMetadata: \(credentialRequestMetadata)
        )
        """
    }

    public init(
        credentialRequest: AnonCredsCredentialRequest,
        credentialRequestMetadata: AnonCredsCredentialRequestMetadata
    ) {
        self.credentialRequest = credentialRequest
        self.credentialRequestMetadata = credentialRequestMetadata
    }
}
