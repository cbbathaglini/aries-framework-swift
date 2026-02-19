//
//  ProcessPresentationReturn.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/10/25.
//

import Foundation

public struct ProcessPresentationReturn: Codable, CustomStringConvertible {
    public let isValid: Bool
    public let message: String?

    public init(isValid: Bool = true, message: String? = nil) {
        self.isValid = isValid
        self.message = message
    }

    public var description: String {
        return "ProcessPresentationReturn(isValid: \(isValid), message: \(message ?? "nil"))"
    }
}
