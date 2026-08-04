//
//  RevocationIdentifier.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/25.
//

import Foundation

public struct RevocationIdentifier {
    
    public static let v1ThreadRegex = try! NSRegularExpression(
        pattern: #"^(indy)::((?:[\dA-Za-z]{21,22}):4:(?:[\dA-Za-z]{21,22}):3:[Cc][Ll]:(?:(?:[1-9][0-9]*)|(?:[\dA-Za-z]{21,22}:2:.+:[0-9.]+)):.+?:CL_ACCUM:(?:[\dA-Za-z-]+))::(\d+)$"#
    )
    
    public static let v2IndyRevocationIdentifierRegex = try! NSRegularExpression(
        pattern: #"^((?:[\dA-Za-z]{21,22}):4:(?:[\dA-Za-z]{21,22}):3:[Cc][Ll]:(?:(?:[1-9][0-9]*)|(?:[\dA-Za-z]{21,22}:2:.+:[0-9.]+)):.+?:CL_ACCUM:(?:[\dA-Za-z-]+))::(\d+)$"#
    )

    public static let v2IndyRevocationFormat = "indy-anoncreds"

    public static let v2AnonCredsRevocationIdentifierRegex = try! NSRegularExpression(
        pattern: #"^([a-zA-Z0-9+\-.]+:.+)::(\d+)$"#
    )

    public static let v2AnonCredsRevocationFormat = "anoncreds"
}
