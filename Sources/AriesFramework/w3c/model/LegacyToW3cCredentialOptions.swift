//
//  LegacyToW3cCredentialOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct LegacyToW3cCredentialOptions: Codable {
    public let credential: AnonCredsCredential
    public let issuerId: String
    public let processOptions: ProcessOptions?

    init(credential: AnonCredsCredential, issuerId: String, processOptions: ProcessOptions? = nil) {
        self.credential = credential
        self.issuerId = issuerId
        self.processOptions = processOptions
    }
}
