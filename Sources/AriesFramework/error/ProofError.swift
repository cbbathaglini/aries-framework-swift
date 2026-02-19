//
//  ProofError.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 15/10/25.
//

public class ProofError: BaseError {
    public init(_ message: String, cause: Error? = nil) {
        super.init(message: message, cause: cause)
    }
}

