//
//  CreateLinkSecretOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct CreateLinkSecretOptions: Codable {
    public let linkSecretId: String?

    public init(linkSecretId: String?) {
        self.linkSecretId = linkSecretId
    }
}
