//
//  AnonCredsAcceptOfferFormatBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework

final class AnonCredsAcceptOfferFormatBuilder {

    private var linkSecretId: String? = "default-link-secret"

    // MARK: - Fluent setters

    func withLinkSecretId(_ id: String?) -> Self {
        self.linkSecretId = id
        return self
    }

    // MARK: - Build

    func build() -> AnonCredsAcceptOfferFormat {
        AnonCredsAcceptOfferFormat(
            linkSecretId: linkSecretId
        )
    }
}
