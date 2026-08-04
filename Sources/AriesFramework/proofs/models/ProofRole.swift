//
//  ProofRole.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

public enum ProofRole: String, Codable {
    case verifier = "verifier"
    case prover = "prover"
    
    public var description: String {
        return rawValue
    }
}
