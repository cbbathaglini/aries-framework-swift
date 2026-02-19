//
//  CredentialRole.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/25.
//

import Foundation

public enum CredentialRole: String, Codable {
    case holder = "Holder"
    case issuer = "Issuer"
    
    public var description: String {
        switch self {
        case .holder:
            return "Holder"
        case .issuer:
            return "Issuer"
        }
    }
}
