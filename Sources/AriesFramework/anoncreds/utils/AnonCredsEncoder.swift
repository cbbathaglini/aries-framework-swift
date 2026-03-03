//
//  AnonCredsEncoder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation
import CryptoKit
import BigInt

public final class AnonCredsEncoder {

    
    //ajuda do chat -> copia do credo-ts
    public static func encodeCredentialValue(_ input: Any?) -> String {
        // Helper: string empty exactly ""
        func isEmptyString(_ v: Any?) -> Bool {
            guard let s = v as? String else { return false }
            return s == ""
        }

        // Helper: check CFBoolean bridging (Bool sometimes arrives as NSNumber)
        func isCFBooleanNumber(_ n: NSNumber) -> Bool {
            CFGetTypeID(n) == CFBooleanGetTypeID()
        }

        // Helper: is Int32 range
        func isInt32(_ d: Double) -> Bool {
            d >= Double(Int32.min) && d <= Double(Int32.max)
        }

        // Helper: "isNumeric" similar to credo-ts (string must be numeric, no junk)
        // Accepts: "-1", "+1", "001", "0"
        // Rejects: "1.2", "1e3", " 1", "1 ", "1a"
        func isNumericIntString(_ s: String) -> Bool {
            // Strict integer regex (no spaces)
            // Equivalent intent to isNumeric + isInt32(Number(value)) in credo
            let pattern = #"^[+-]?\d+$"#
            return s.range(of: pattern, options: .regularExpression) != nil
        }

        // 1) Bool -> "0"/"1"
        if let b = input as? Bool {
            return b ? "1" : "0"
        }

        // 2) Number + isInt32(number) -> number.toString()
        if let n = input as? NSNumber {
            // If it's actually a Bool-as-NSNumber, handle like bool
            if isCFBooleanNumber(n) {
                return n.boolValue ? "1" : "0"
            }

            let d = n.doubleValue

            // credo-ts: isNumber && isInt32(value)
            // In JS, `isNumber` includes ints + floats, but the isInt32 check must pass.
            // Treat as Int32 ONLY if it's an exact integer and in Int32 range.
            if d.isFinite, d.rounded(.towardZero) == d, isInt32(d) {
                return String(Int32(d))
            }

            // credo-ts: if (isNumber(value)) value = value.toString()
            // so for non-int32 numbers we convert to string and hash later.
            let asString = n.stringValue  // produces a reasonable JS-like string for numbers
            return sha256Encode(asString)
        }

        // 3) String numeric int32 -> Number(value).toString()
        if let s = input as? String {
            // credo: if isString && !isEmpty && !NaN(Number(value)) && isNumeric(value) && isInt32(Number(value))
            if !isEmptyString(s),
               isNumericIntString(s),
               let d = Double(s),
               d.isFinite,
               d.rounded(.towardZero) == d,
               isInt32(d) {
                // Number(value).toString() normaliza "0001" -> "1", "+1" -> "1", "-0" -> "0"
                return String(Int32(d))
            }

            // credo: empty string is NOT converted to "None"; it gets hashed as ""
            return sha256Encode(s)
        }

        // 4) null/undefined -> "None" -> hash
        guard let v = input else {
            return sha256Encode("None")
        }

        // 5) Fallback: hash String(value)
        return sha256Encode(String(describing: v))
    }

    private static func sha256Encode(_ input: String) -> String {
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        let bigint = BigUInt(Data(digest)) // big-endian unsigned
        return bigint.description          // base10
    }
}

//versão antiga
//import Foundation
//import CryptoKit
//import BigInt
//
//public class AnonCredsEncoder {
//
//    public static func encodeCredentialValue(_ value: Any?) -> String {
//            
//            guard let value = value else {
//                return sha256Encode("None")
//            }
//            
//            if let b = value as? Bool {
//                return b ? "1" : "0"
//            }
//            
//            if let n = value as? NSNumber {
//                let doubleValue = n.doubleValue
//                if doubleValue.rounded(.towardZero) == doubleValue {
//                    if doubleValue >= Double(Int32.min) && doubleValue <= Double(Int32.max) {
//                        return String(Int32(doubleValue))
//                    }
//                }
//            }
//            
//            if let s = value as? String {
//                let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
//                
//                if trimmed.isEmpty {
//                    return sha256Encode("None")
//                }
//                
//                if let intValue = Int32(trimmed) {
//                    return String(intValue)
//                }
//                
//                
//                return sha256Encode(trimmed)
//            }
//            
//            return sha256Encode(String(describing: value))
//    
//    }
//
//
//    private static func sha256Encode(_ input: String) -> String {
//        let data = Data(input.utf8)
//        let hash = SHA256.hash(data: data)
//        let bigint = BigUInt(Data(hash))
//        return bigint.description
//    }
//}
