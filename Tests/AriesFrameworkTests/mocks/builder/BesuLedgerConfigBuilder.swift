//
//  BesuLedgerConfigBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/26.
//


@testable import AriesFramework
import Foundation

final class BesuLedgerConfigBuilder {

    private var configFile: String = "mock-besu-config.json"
    private var multiledger: Bool = false

    @discardableResult
    func setConfigFile(_ value: String) -> Self {
        self.configFile = value
        return self
    }

    @discardableResult
    func setMultiledger(_ value: Bool) -> Self {
        self.multiledger = value
        return self
    }

    func build() -> BesuLedgerConfig {
        BesuLedgerConfig(
            configFile: configFile,
            multiledger: multiledger
        )
    }
}
