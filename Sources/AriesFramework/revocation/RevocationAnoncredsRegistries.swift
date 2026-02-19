//
//  RevocationAnoncredsRegistries.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 18/11/25.
//

public class RevocationAnoncredsRegistries: CustomStringConvertible {
    
    public var registries: [String: AnonCredsRevocationRegistryEntry]
    public var updatedSelectedCredentials: AnonCredsSelectedCredentials
    

    init(
        registries: [String: AnonCredsRevocationRegistryEntry],
        updatedSelectedCredentials: AnonCredsSelectedCredentials
    ) {
        self.registries = registries
        self.updatedSelectedCredentials = updatedSelectedCredentials
    }
    

    public var description: String {
        return """
        RevocationAnoncredsRegistries:
          registries count: \(registries.count)
          updatedSelectedCredentials: \(updatedSelectedCredentials)
        """
    }
}
