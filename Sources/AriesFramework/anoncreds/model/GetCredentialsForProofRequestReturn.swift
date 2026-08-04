//
//  GetCredentialsForProofRequestReturn.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct GetCredentialsForProofRequestReturn: Codable {
    public var credentials: [CredentialForProofRequest]
}

public struct CredentialForProofRequest: Codable {
    public var credentialInfo: AnonCredsCredentialInfo
    public var interval: AnonCredsNonRevokedInterval?
}

public struct AnonCredsNonRevokedInterval: Codable {
    public var from: UInt64?
    public var to: UInt64?
        
    public init(from: UInt64?, to: UInt64?) {
        self.from = from
        self.to = to
    }
}
