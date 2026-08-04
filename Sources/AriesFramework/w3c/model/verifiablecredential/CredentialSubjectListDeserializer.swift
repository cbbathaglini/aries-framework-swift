//
//  CredentialSubjectListDeserializer.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 22/04/25.
//

import Foundation

class CredentialSubjectListDeserializer {
    static func decode(from decoder: Decoder) throws -> [CredentialSubject] {
        let container = try decoder.singleValueContainer()
        
        do {
            return try container.decode([CredentialSubject].self)
        } catch {
            let single = try container.decode(CredentialSubject.self)
            return [single]
        }
    }
}
