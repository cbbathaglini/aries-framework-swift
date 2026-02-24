//
//  DefaultCredentialV2DependenciesProvider.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 23/02/26.
//

public struct DefaultCredentialV2DependenciesProvider: CredentialV2DependenciesProviding {
    public init() {}

    public func makeFormatServices(agent: Agent) -> [any CredentialFormatService] {
        [AnoncredsCredentialFormatService(agent: agent)]
    }

    public func makeCoordinator(
        agent: Agent,
        formatServices: [any CredentialFormatService]
    ) -> any CredentialFormatCoordinatorProtocol {
        CredentialFormatCoordinator(agent: agent, formatServices: formatServices)
    }
}
