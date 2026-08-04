//
//  RetrievedCredentialsAnonCreds.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/10/25.
//

import Foundation

public struct RetrievedCredentialsAnonCreds: Codable {
    public var requestedAttributes: [String: [RequestedAttributeAnonCreds]] = [:]
    public var requestedPredicates: [String: [RequestedPredicateAnonCreds]] = [:]
}
