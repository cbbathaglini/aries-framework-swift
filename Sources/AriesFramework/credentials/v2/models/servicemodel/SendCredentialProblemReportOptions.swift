//
//  SendCredentialProblemReportOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation

public struct SendCredentialProblemReportOptions: Codable {
    public var credentialRecordId: String
    public var description: String

    public init(credentialRecordId: String, description: String) {
        self.credentialRecordId = credentialRecordId
        self.description = description
    }
}
