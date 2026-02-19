//
//  CredDefVdrCacheDto.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/02/26.
//

import Foundation
import indy_besu_vdr_uniffi

public struct CredDefVdrCacheDto: Codable{
    let issuerId: String
    let schemaId: String
    let credDefType: String
    let tag: String
    let value: String
    
    init(from v: indy_besu_vdr_uniffi.CredentialDefinition) {
        self.issuerId = v.issuerId
        self.schemaId = v.schemaId
        self.credDefType = v.credDefType
        self.tag = v.tag
        self.value = v.value
    }
    

    
    public func toVdr() -> indy_besu_vdr_uniffi.CredentialDefinition {
        return indy_besu_vdr_uniffi.CredentialDefinition(
            issuerId: issuerId,
            schemaId: schemaId,
            credDefType: credDefType,
            tag: tag,
            value: value
        )
    }
    
}
