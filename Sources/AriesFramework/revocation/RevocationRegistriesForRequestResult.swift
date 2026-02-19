//
//  RevocationRegistriesForRequestResult.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

public struct RevocationRegistriesForRequestResult {
    let revocationRegistries: [String: RevocationRegistryBucket]
    let updatedSelectedCredentials: AnonCredsSelectedCredentials
}

