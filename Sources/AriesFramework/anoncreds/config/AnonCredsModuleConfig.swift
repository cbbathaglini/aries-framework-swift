//
//  AnonCredsModuleConfig.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation

public class AnonCredsModuleConfig {

    public let agent: Agent
    private let options: AnonCredsModuleConfigOptions?

    public init(agent: Agent, options: AnonCredsModuleConfigOptions? = nil) {
        self.agent = agent
        self.options = options
    }

    public var registries: [AnonCredsRegistry] {
        return options?.registries ?? []
    }

    public var tailsFileService: TailsFileService {
        return options?.tailsFileService ?? BasicTailsFileService(agent: agent)
    }

    public var anoncreds: Any? {
        return options?.anoncreds
    }

    public var autoCreateLinkSecret: Bool {
        return options?.autoCreateLinkSecret ?? true
    }
}
