//
//  CredentialSubjectWrapper.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 22/04/25.
//

struct CredentialSubjectWrapper: Decodable {
    let subjects: [CredentialSubject]
    
    init(from decoder: Decoder) throws {
        self.subjects = try CredentialSubjectListDeserializer.decode(from: decoder)
    }
}
