//
//  W3cJsonLdCredentialService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation
import AnyCodable

public class W3cJsonLdCredentialService {
    private let agent: Agent
    private let config: W3cCredentialsModuleConfig
    private let appContext: Any

    init(agent: Agent, config: W3cCredentialsModuleConfig, context: Any) {
        self.agent = agent
        self.config = config
        self.appContext = context
    }

    public func getExpandedTypesForCredential(
        contextList: [AnyCodable],
        types: [String]
    ) throws -> [String: [String]] {
        let expandedTypes = W3cTypeExpander.expandTypes(
            spec: W3cTypeExpander.ContextSpec(contexts: contextList),
            types: types
        )

        return ["type": expandedTypes]
    }
}
