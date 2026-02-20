//
//  CreateCredentialReturn.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct CreateCredentialReturn: Codable, CustomStringConvertible {
    let credential: AnonCredsCredential
    let credentialRevocationId: String?

    public var description: String {
        return "CreateCredentialReturn(credential: \(credential), credentialRevocationId: \(credentialRevocationId ?? "nil"))"
    }
}
