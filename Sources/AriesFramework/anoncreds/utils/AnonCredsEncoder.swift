//
//  AnonCredsEncoder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation
import CryptoKit
import BigInt

public class AnonCredsEncoder {

    public static func encodeCredentialValue(_ value: Any?) -> String {
        
            
            guard let value = value else {
                return sha256Encode("None")
            }
            
            if let b = value as? Bool {
                return b ? "1" : "0"
            }
            
            if let n = value as? NSNumber {
                let intValue = n.intValue
                if intValue <= Int32.max && intValue >= Int32.min {
                    return String(intValue)
                }
            }
            
            if let s = value as? String {
                let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if trimmed.isEmpty {
                    return sha256Encode("None")
                }
                
                if let intValue = Int32(trimmed) {
                    return String(intValue)
                }
                
                
                return sha256Encode(trimmed)
            }
            
            return sha256Encode(String(describing: value))
    
    }


    private static func sha256Encode(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        let bigint = BigUInt(Data(hash))
        return bigint.description
    }
}
