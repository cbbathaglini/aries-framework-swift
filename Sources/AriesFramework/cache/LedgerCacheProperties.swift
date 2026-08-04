//
//  LedgerCacheProperties.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 03/02/26.
//

import Foundation

final class LedgerCacheProperties {

    private let cfg: LedgerCacheConfig

    init(bundle: Bundle = .main) {
        self.cfg = LedgerCacheConfig.loadFromInfoPlist(bundle: bundle)
    }

    func defaultTtlDays() -> Int64 {
        cfg.credDefDefaultDays
    }

    func schemaTtlDays() -> Int64 {
        cfg.schemaTtlDays
    }

    func revRegTtlDays() -> Int64 {
        cfg.revRegTtlDays
    }

    func tailsTtlDays() -> Int64 {
        cfg.tailsTtlDays
    }

    func credDefTtlDays(for credDefId: String) -> Int64 {
        cfg.credDefTtlDaysById[credDefId] ?? cfg.credDefDefaultDays
    }
}
