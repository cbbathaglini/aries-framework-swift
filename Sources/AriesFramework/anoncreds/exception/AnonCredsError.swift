//
//  AnonCredsError.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

class AnonCredsError: Error, CustomStringConvertible {
    let message: String
    let cause: Error?

    init(_ message: String, cause: Error? = nil) {
        self.message = message
        self.cause = cause
    }

    var description: String {
        if let cause = cause {
            return "AnonCredsError(message: \(message), cause: \(cause))"
        } else {
            return "AnonCredsError(message: \(message))"
        }
    }
}
