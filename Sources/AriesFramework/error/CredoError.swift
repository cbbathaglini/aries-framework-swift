//
//  CredoError.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/25.
//

import Foundation

open class BaseError: LocalizedError {
    public let message: String
    public let cause: Error?

    public init(message: String, cause: Error? = nil) {
        self.message = message
        self.cause = cause
    }

    public var errorDescription: String? {
        return message
    }
}

public class CredoError: BaseError {
    public init(_ message: String, cause: Error? = nil) {
        super.init(message: message, cause: cause)
    }
}


public class NotFoundError: BaseError {
    public init(_ message: String, cause: Error? = nil) {
        super.init(message: message, cause: cause)
    }
}
