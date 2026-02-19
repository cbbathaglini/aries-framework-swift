//
//  MetadataKeys.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

enum MetadataKeys {
    /// Metadata key for strong metadata on an AnonCreds credential.
    /// MUST be used with `AnonCredsCredentialMetadata`
    static let anonCredsCredentialMetadataKey = "_anoncreds/credential"
    
    /// Metadata key for storing metadata on an AnonCreds credential request.
    /// MUST be used with `AnonCredsCredentialRequestMetadata`
    static let anonCredsCredentialRequestMetadataKey = "_anoncreds/credentialRequest"
    
    /// Metadata key for storing the W3C AnonCreds credential metadata.
    /// MUST be used with `W3cAnonCredsCredentialMetadata`
    static let w3cAnonCredsCredentialMetadataKey = "_w3c/anonCredsMetadata"
    
    static let presentationProofTime = "presentationProofTime"
}
