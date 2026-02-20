//
//  AnonCredsRegistryServiceProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/01/26.
//

public protocol AnonCredsRegistryServiceProtocol {
    func getRegistryForIdentifier(for identifier: String) throws -> AnonCredsRegistry
}
