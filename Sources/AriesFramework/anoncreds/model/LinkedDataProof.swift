//
//  LinkedDataProof.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

public struct LinkedDataProof: Codable, LinkedDataProofBase {
    public let type: String
    public let created: String
    public let proofPurpose: String
    public let verificationMethod: String
    public let jws: String?
}
