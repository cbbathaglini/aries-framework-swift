//
//  RevocationRegistryBucket.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

import Foundation
import indy_besu_vdr_uniffi

public struct RevocationRegistryBucket {
    let definition: indy_besu_vdr_uniffi.RevocationRegistryDefinition
    let tailsFilePath: String?
    let tailsHash: String?
    var revocationStatusLists: [UInt64: indy_besu_vdr_uniffi.RevocationStatusList]? = nil
}
