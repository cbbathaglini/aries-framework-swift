//
//  ProofFormat.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 20/03/25.
//

import Foundation

public class ProofFormat: Codable {
    var attach_id: String = "indy"
    var format: String = "hlindy/proof-req@v2.0"
    
    func toJsonString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let jsonData = try encoder.encode(self)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Error encoding JSON: \(error)")
            return nil
        }
    }
}
