//
//  AnonCredsRevocationRegistryState.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public enum AnonCredsRevocationRegistryState: String, Codable {
    case created = "created"
    case active = "active"
    case full = "full"
}
