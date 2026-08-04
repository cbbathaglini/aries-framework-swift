//
//  FetchIntermediateRevocationRegistryDefinitionResult.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct FetchIntermediateRevocationRegistryDefinitionResult: Codable {
    var id: String?
    let issuerId: String
    let revocDefType: String
    let credDefId: String
    let tag: String
    let value: RevocationRegistryValue
    var revocationRegistryDefinitionId: String?
    let indyNamespace: String?

    init(
        id: String? = nil,
        issuerId: String,
        revocDefType: String = "CL_ACCUM",
        credDefId: String,
        tag: String,
        value: RevocationRegistryValue,
        revocationRegistryDefinitionId: String? = nil,
        indyNamespace: String? = nil
    ) {
        self.id = id
        self.issuerId = issuerId
        self.revocDefType = revocDefType
        self.credDefId = credDefId
        self.tag = tag
        self.value = value
        self.revocationRegistryDefinitionId = revocationRegistryDefinitionId
        self.indyNamespace = indyNamespace
    }
}
