//
//  HashlinkEncoder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation
import CryptoKit
import BigInt

public struct HashlinkEncoder {
    private static let alphabet = Array("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")

    public static func encode(bytes: [UInt8], hashAlgorithm: String, baseName: String) -> String {
        let digest: [UInt8]

        switch hashAlgorithm.lowercased() {
        case "sha-256":
            digest = [UInt8](SHA256.hash(data: Data(bytes)))
        default:
            fatalError("Unsupported hash algorithm: \(hashAlgorithm)")
        }

        let encoded = base58btcEncode(digest)
        return "hl:\(encoded)"
    }

    public static func isValid(hashlink: String) -> Bool {
        return hashlink.starts(with: "hl:") && hashlink.count > 3
    }

    private static func base58btcEncode(_ input: [UInt8]) -> String {
        var intData = input.reduce(BigUInt(0)) { (acc, byte) in
            (acc << 8) + BigUInt(byte)
        }

        var result = ""
        while intData > 0 {
            let (quotient, remainder) = intData.quotientAndRemainder(dividingBy: 58)
            result = String(alphabet[Int(remainder)]) + result
            intData = quotient
        }

        for byte in input where byte == 0 {
            result = String(alphabet[0]) + result
        }

        return result
    }
}
