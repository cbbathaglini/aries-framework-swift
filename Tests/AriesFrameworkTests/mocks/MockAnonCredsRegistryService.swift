//
//  MockAnonCredsRegistryService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/01/26.
//


@testable import AriesFramework
import Foundation

@testable import AriesFramework

final class MockAnonCredsRegistryService: AnonCredsRegistryServiceProtocol {

    private let registry: AnonCredsRegistry

    init(registry: AnonCredsRegistry) {
        self.registry = registry
    }

    func getRegistryForIdentifier(for identifier: String) throws -> AnonCredsRegistry {
        return registry
    }
}
