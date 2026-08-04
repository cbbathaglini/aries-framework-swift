//
//  GetRevocationStatusListReturn.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation
import AnyCodable

public struct GetRevocationStatusListReturn: Codable {
    public let revocationStatusList: AnonCredsRevocationStatusList?
    public let resolutionMetadata: AnonCredsResolutionMetadata?
    public let revocationStatusListMetadata: [String: AnyCodable]

    public init(
        revocationStatusList: AnonCredsRevocationStatusList? = nil,
        resolutionMetadata: AnonCredsResolutionMetadata? = nil,
        revocationStatusListMetadata: [String: AnyCodable] = [:]
    ) {
        self.revocationStatusList = revocationStatusList
        self.resolutionMetadata = resolutionMetadata
        self.revocationStatusListMetadata = revocationStatusListMetadata
    }
}
