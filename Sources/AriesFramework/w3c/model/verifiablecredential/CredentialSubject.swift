//
//  CredentialSubject.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 22/04/25.
//
import Foundation
import AnyCodable

public class CredentialSubject: Codable {
    var id: String?
    var dynamicAttributes: [String: AnyCodable] = [:]
    
    public init(id: String? = nil, dynamicAttributes: [String: AnyCodable] = [:]) {
        self.id = id
        self.dynamicAttributes = dynamicAttributes
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case id
        // Dynamic attributes will be handled manually
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        
        // Handle dynamic attributes
        let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
        for key in dynamicContainer.allKeys {
            if key.stringValue != CodingKeys.id.stringValue {
                dynamicAttributes[key.stringValue] = try dynamicContainer.decode(AnyCodable.self, forKey: key)
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        
        // Encode dynamic attributes
        var dynamicContainer = encoder.container(keyedBy: DynamicCodingKey.self)
        for (key, value) in dynamicAttributes {
            try dynamicContainer.encode(value, forKey: DynamicCodingKey(stringValue: key)!)
        }
    }
    
    // Helper for dynamic keys
    private struct DynamicCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }
        
        init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }
    
    
    func toJson() -> String {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys // For consistent output
            
            var dict: [String: AnyCodable] = [:]
            if let id = id {
                dict["id"] = AnyCodable(id)
            }
            // Add dynamic attributes
            for (key, value) in dynamicAttributes {
                dict[key] = value
            }
            
            let jsonData = try encoder.encode(dict)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
            return "{}"
        } catch {
            print("Error converting CredentialSubject to JSON: \(error)")
            return "{}"
        }
    }
}
