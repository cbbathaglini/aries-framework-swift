//
//  AnonCredsResolutionMetadata.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation
import AnyCodable

public struct AnonCredsResolutionMetadata: Codable {
    public let error: String?
    public let message: String?
    public let extensible: [String: AnyCodable]

    public init(
        error: String? = nil,
        message: String? = nil,
        extensible: [String: AnyCodable] = [:]
    ) {
        self.error = error
        self.message = message
        self.extensible = extensible
    }
}
