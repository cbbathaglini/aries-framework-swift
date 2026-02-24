//
//  CredentialV2DependenciesProviding.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 23/02/26.
//

public protocol CredentialV2DependenciesProviding {
    func makeFormatServices(agent: Agent) -> [any CredentialFormatService]
    func makeCoordinator(agent: Agent, formatServices: [any CredentialFormatService]) -> any CredentialFormatCoordinatorProtocol
}
