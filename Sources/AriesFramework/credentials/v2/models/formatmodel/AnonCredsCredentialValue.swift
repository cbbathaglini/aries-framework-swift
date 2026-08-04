//
//  AnonCredsCredentialValue.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

public struct AnonCredsCredentialValue: Codable {
    public let raw: String
    public let encoded: String
}

typealias AnonCredsCredentialValues = [String: AnonCredsCredentialValue]
