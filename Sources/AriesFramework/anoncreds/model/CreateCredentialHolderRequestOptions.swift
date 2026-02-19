//
//  CreateCredentialHolderRequestOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 01/10/25.
//

struct CreateCredentialHolderRequestOptions: Codable {
    let credentialOffer: AnonCredsCredentialOffer
    let credentialDefinition: String
    let linkSecretId: String?
    let useLegacyProverDid: Bool?

    init(
        credentialOffer: AnonCredsCredentialOffer,
        credentialDefinition: String,
        linkSecretId: String? = nil,
        useLegacyProverDid: Bool? = nil
    ) {
        self.credentialOffer = credentialOffer
        self.credentialDefinition = credentialDefinition
        self.linkSecretId = linkSecretId
        self.useLegacyProverDid = useLegacyProverDid
    }
}
