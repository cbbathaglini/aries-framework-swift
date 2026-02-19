//
//  DataIntegrityProof.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

public struct DataIntegrityProof: LinkedDataProofBase, Codable {
    public let type: String
    public let cryptosuite: String
    public let created: String?
    public let proofPurpose: String
    public let verificationMethod: String
    public let proofValue: String?
}
