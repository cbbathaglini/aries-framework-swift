//
//  GetCredentialsForProofRequestReturnBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/26.
//
import Foundation
@testable import AriesFramework

final class GetCredentialsForProofRequestReturnBuilder {

    private var credentials: [CredentialForProofRequest] = []

    @discardableResult
    func setCredentials(_ value: [CredentialForProofRequest]) -> Self {
        self.credentials = value
        return self
    }

    func build() -> GetCredentialsForProofRequestReturn {
        GetCredentialsForProofRequestReturn(credentials: credentials)
    }
}
