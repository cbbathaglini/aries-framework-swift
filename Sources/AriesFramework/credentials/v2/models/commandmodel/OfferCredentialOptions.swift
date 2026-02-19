//
//  OfferCredentialOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 01/10/25.
//

import Foundation
import AnyCodable

public struct OfferCredentialOptions: Codable {
    public let connectionId: String
    public let comment: String?
    public let goalCode: String?
    public let goal: String?
    public let autoAcceptCredential: AutoAcceptCredential?
    public let protocolVersion: String
    public let credentialFormat: [String: AnyCodable]

    public init(
        connectionId: String,
        comment: String? = nil,
        goalCode: String? = nil,
        goal: String? = nil,
        autoAcceptCredential: AutoAcceptCredential? = nil,
        protocolVersion: String,
        credentialFormat: [String: AnyCodable]
    ) {
        self.connectionId = connectionId
        self.comment = comment
        self.goalCode = goalCode
        self.goal = goal
        self.autoAcceptCredential = autoAcceptCredential
        self.protocolVersion = protocolVersion
        self.credentialFormat = credentialFormat
    }
}
