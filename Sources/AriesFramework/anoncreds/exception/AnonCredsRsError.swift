//
//  AnonCredsRsError.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//

class AnonCredsRsError: AnonCredsError {
    override init(_ message: String, cause: Error? = nil) {
        super.init(message, cause: cause)
    }

    override var description: String {
        if let cause = cause {
            return "AnonCredsRsError(message: \(message), cause: \(cause))"
        } else {
            return "AnonCredsRsError(message: \(message))"
        }
    }
}
