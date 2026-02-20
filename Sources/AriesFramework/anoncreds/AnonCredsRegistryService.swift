//
//  AnonCredsRegistryService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation
import os

public class AnonCredsRegistryService : AnonCredsRegistryServiceProtocol{
    private let agent: Agent
    private let logger = Logger(subsystem: "org.hyperledger.ariesframework", category: "AnonCredsRegistryService")


    public init(agent: Agent) {
        self.agent = agent
    }

    public func getRegistryForIdentifier(for identifier: String) throws -> AnonCredsRegistry {
        let registries = agent.anoncredsModulesConfig.registries
        logDebug("registries: \(registries)")

        if let registry = registries.first(where: {
            let regex = $0.supportedIdentifier
            let range = NSRange(location: 0, length: identifier.utf16.count)
            return regex.firstMatch(in: identifier, options: [], range: range) != nil
        }) {
            return registry
        }

        throw AnonCredsError("No AnonCredsRegistry registered for identifier '\(identifier)'")
    }
}
