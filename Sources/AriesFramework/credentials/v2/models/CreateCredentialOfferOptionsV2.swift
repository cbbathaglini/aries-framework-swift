//
//  CreateCredentialOfferOptionsV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

public struct CreateCredentialOfferOptionsV2 {
    public let credentialFormat: [String: Any]
    public let autoAcceptCredential: AutoAcceptCredential?
    public let comment: String?
    public let goal: String?
    public let goalCode: String?
    public let connectionRecord: ConnectionRecord?

    public init(
        credentialFormat: [String: Any],
        autoAcceptCredential: AutoAcceptCredential? = nil,
        comment: String? = nil,
        goal: String? = nil,
        goalCode: String? = nil,
        connectionRecord: ConnectionRecord? = nil
    ) {
        self.credentialFormat = credentialFormat
        self.autoAcceptCredential = autoAcceptCredential
        self.comment = comment
        self.goal = goal
        self.goalCode = goalCode
        self.connectionRecord = connectionRecord
    }
}
