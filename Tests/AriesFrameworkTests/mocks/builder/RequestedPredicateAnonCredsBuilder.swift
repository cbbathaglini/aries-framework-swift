//
//  RequestedPredicateAnonCredsBuilder.swift
//  aries-framework-swiftTests
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/26.
//

import Foundation
@testable import AriesFramework

final class RequestedPredicateAnonCredsBuilder {

    private var credentialId: String = "cred-id"
    private var timestamp: Int? = nil
    private var credentialInfo: AnonCredsCredentialInfo? = nil
    private var revoked: Bool? = nil

    @discardableResult
    func setCredentialId(_ value: String) -> Self {
        self.credentialId = value
        return self
    }

    @discardableResult
    func setTimestamp(_ value: Int?) -> Self {
        self.timestamp = value
        return self
    }

    @discardableResult
    func setCredentialInfo(_ value: AnonCredsCredentialInfo?) -> Self {
        self.credentialInfo = value
        return self
    }

    @discardableResult
    func setRevoked(_ value: Bool?) -> Self {
        self.revoked = value
        return self
    }

    func build() -> RequestedPredicateAnonCreds {
        RequestedPredicateAnonCreds(
            credentialId: credentialId,
            timestamp: timestamp,
            credentialInfo: credentialInfo,
            revoked: revoked
        )
    }
}
