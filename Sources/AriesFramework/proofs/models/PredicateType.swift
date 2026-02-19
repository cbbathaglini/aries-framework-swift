//
//  PredicateType.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//
import Foundation

public enum PredicateType: String, Codable {
    case LessThan = "<"
    case LessThanOrEqualTo = "<="
    case GreaterThan = ">"
    case GreaterThanOrEqualTo = ">="
    
    public static func fromString(_ value: String) throws -> PredicateType {
        switch value {
        case "<", "LessThan":
            return .LessThan
        case "<=", "LessThanOrEqualTo":
            return .LessThanOrEqualTo
        case ">", "GreaterThan":
            return .GreaterThan
        case ">=", "GreaterThanOrEqualTo":
            return .GreaterThanOrEqualTo
        default:
            throw NSError(domain: "PredicateType", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Unknown PredicateType: \(value)"
            ])
        }
    }
}
