//
//  AnonCredsNonRevokedIntervalBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/26.
//

import Foundation
@testable import AriesFramework

final class AnonCredsNonRevokedIntervalBuilder {

    private var from: UInt64? = nil
    private var to: UInt64? = nil

    @discardableResult
    func setFrom(_ value: UInt64?) -> Self {
        self.from = value
        return self
    }

    @discardableResult
    func setTo(_ value: UInt64?) -> Self {
        self.to = value
        return self
    }

    func build() -> AnonCredsNonRevokedInterval {
        AnonCredsNonRevokedInterval(from: from, to: to)
    }
}
