//
//  W3cAnonCredsCredentialMetadata.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//

import Foundation

public struct W3cAnonCredsCredentialMetadata: Codable {
    public let methodName: String
    public let credentialRevocationId: String?
    public let linkSecretId: String

    public init(
        methodName: String,
        credentialRevocationId: String? = nil,
        linkSecretId: String
    ) {
        self.methodName = methodName
        self.credentialRevocationId = credentialRevocationId
        self.linkSecretId = linkSecretId
    }
}
