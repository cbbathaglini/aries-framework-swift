//
//  LedgerCacheDefaults.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 03/02/26.
//

enum LedgerCacheDefaults {
    static let TAILS_PATH = "tailsPath"
    static let SCHEMA_JSON = "schemaJson"
    static let CRED_DEF = "credDefJson"
    static let CRED_DEF_VDR = "credDefVdrJson"
    static let REG_DEF = "regDef"

    static let defaultTtlDays: Int = 1
    static let defaultRules: String = ""
}
