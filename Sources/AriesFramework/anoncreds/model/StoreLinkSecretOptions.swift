//
//  StoreLinkSecretOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//

import Foundation

struct StoreLinkSecretOptions: Codable {
    let linkSecretId: String
    let linkSecretValue: String?
    let setAsDefault: Bool

    init(linkSecretId: String, linkSecretValue: String? = nil, setAsDefault: Bool = false) {
        self.linkSecretId = linkSecretId
        self.linkSecretValue = linkSecretValue
        self.setAsDefault = setAsDefault
    }
}
