//
//  CreateLinkSecretReturn.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct CreateLinkSecretReturn: Codable {
    public let linkSecretId: String
    public let linkSecret: String?

    public init(linkSecretId: String, linkSecret: String? = nil) {
        self.linkSecretId = linkSecretId
        self.linkSecret = linkSecret
    }
}
