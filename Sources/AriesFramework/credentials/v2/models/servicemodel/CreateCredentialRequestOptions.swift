//
//  CreateCredentialRequestOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation

public struct CreateCredentialRequestOptions: Codable {
    public let credentialFormats: [Format]
    public let autoAcceptCredential: AutoAcceptCredential?
    public let comment: String?
    public let goal: String?
    public let goalCode: String?
    public let connectionRecord: ConnectionRecord

    init(
        credentialFormats: [Format],
        autoAcceptCredential: AutoAcceptCredential? = nil,
        comment: String? = nil,
        goal: String? = nil,
        goalCode: String? = nil,
        connectionRecord: ConnectionRecord
    ) {
        self.credentialFormats = credentialFormats
        self.autoAcceptCredential = autoAcceptCredential
        self.comment = comment
        self.goal = goal
        self.goalCode = goalCode
        self.connectionRecord = connectionRecord
    }
}
