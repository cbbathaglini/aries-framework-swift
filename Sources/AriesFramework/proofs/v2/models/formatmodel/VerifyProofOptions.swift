//
//  VerifyProofOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

public struct VerifyProofOptions: Codable, CustomStringConvertible {
    public var proofRequest: AnonCredsProofRequest
    public var presentationMessage: PresentationMessageV2
    public var requestMessage: RequestPresentationMessageV2
    public var proof: AnonCredsProof
    public var schemas: AnonCredsSchemas
    public var credentialDefinitions: AnonCredsCredentialDefinitions
    public var revocationRegistries: [String: RevocationRegistryEntry]?

    public var description: String {
        return """
        VerifyProofOptions(
          proofRequest: \(proofRequest),
          proof: \(proof),
          schemas: \(schemas),
          credentialDefinitions: \(credentialDefinitions),
          revocationRegistries: \(revocationRegistries)
        )
        """
    }
}
