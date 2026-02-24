//
//  CredentialV2DependenciesProviderTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 23/02/26.
//

import XCTest
@testable import AriesFramework

// MARK: - Test Dependencies Provider

final class TestCredentialV2DependenciesProvider: CredentialV2DependenciesProviding {
    let formatServices: [any CredentialFormatService]
    let coordinator: any CredentialFormatCoordinatorProtocol

    init(
        formatServices: [any CredentialFormatService],
        coordinator: any CredentialFormatCoordinatorProtocol
    ) {
        self.formatServices = formatServices
        self.coordinator = coordinator
    }

    func makeFormatServices(agent: Agent) -> [any CredentialFormatService] {
        formatServices
    }

    func makeCoordinator(
        agent: Agent,
        formatServices: [any CredentialFormatService]
    ) -> any CredentialFormatCoordinatorProtocol {
        coordinator
    }
}

// MARK: - Spy Delegate

final class SpyAgentDelegate: AgentDelegate {
    
    // MARK: - Credential V2
    
    private(set) var onCredentialStateV2ChangedCalled = false
    private(set) var onCredentialStateV2ChangedCallCount = 0
    private(set) var lastCredentialRecord: CredentialExchangeRecord?
    
    func onCredentialStateV2Changed(credentialRecord: CredentialExchangeRecord) {
        onCredentialStateV2ChangedCalled = true
        onCredentialStateV2ChangedCallCount += 1
        lastCredentialRecord = credentialRecord
    }
    
    // MARK: - Helpers
    
    func reset() {
        onCredentialStateV2ChangedCalled = false
        onCredentialStateV2ChangedCallCount = 0
        lastCredentialRecord = nil
    }
}
