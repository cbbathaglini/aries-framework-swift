//
//  CreateCredentialOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

struct CreateCredentialOptions: Codable {
    let credentialOffer: AnonCredsCredentialOffer
    let credentialRequest: AnonCredsCredentialRequest
    let credentialValues: AnonCredsCredentialValues
    let revocationRegistryDefinitionId: String?
    let revocationStatusList: AnonCredsRevocationStatusList?
    let revocationRegistryIndex: Int?
}
