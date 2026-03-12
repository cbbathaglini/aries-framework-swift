//
//  Base91.swift
//  Runner
//
//  Created by serpro on 05/01/26.
//

import Foundation

public enum Base91 {
    private static let encodingTableString =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" +
        "!#$%&()*+,./:;<=>?@[]^_`{|}~\""

    private static let encodingTable: [UInt8] = Array(encodingTableString.utf8)

    private static let decodingTable: [Int] = {
        var table = Array(repeating: -1, count: 256)
        for (i, b) in encodingTable.enumerated() {
            table[Int(b)] = i
        }
        return table
    }()

    // MARK: - Public API ([UInt8])
    public static func encode(_ data: [UInt8]) -> String {
        var b = 0
        var n = 0
        var out = String()

        for byte in data {
            b |= (Int(byte & 0xFF) << n)
            n += 8

            if n > 13 {
                var v = b & 8191
                if v > 88 {
                    b >>= 13
                    n -= 13
                } else {
                    v = b & 16383
                    b >>= 14
                    n -= 14
                }

                let c1 = encodingTable[v % 91]
                let c2 = encodingTable[v / 91]
                out.append(Character(UnicodeScalar(UInt32(c1))!))
                out.append(Character(UnicodeScalar(UInt32(c2))!))
            }
        }

        if n > 0 {
            let c1 = encodingTable[b % 91]
            out.append(Character(UnicodeScalar(UInt32(c1))!))
            if n > 7 || b > 90 {
                let c2 = encodingTable[b / 91]
                out.append(Character(UnicodeScalar(UInt32(c2))!))
            }
        }

        return out
    }

    public static func decode(_ encoded: String) -> [UInt8] {
        var b = -1
        var n = 0
        var v = 0
        var out: [UInt8] = []

        for scalar in encoded.unicodeScalars {
            let codepoint = Int(scalar.value)
            let c = (codepoint < 256) ? decodingTable[codepoint] : -1
            if c == -1 { continue }

            if b < 0 {
                b = c
            } else {
                b += c * 91
                v |= (b << n)
                n += ((b & 8191) > 88) ? 13 : 14

                while n >= 8 {
                    out.append(UInt8(v & 255))
                    v >>= 8
                    n -= 8
                }

                b = -1
            }
        }

        if b >= 0 {
            out.append(UInt8((v | (b << n)) & 255))
        }

        return out
    }

    // MARK: - Convenience API (Data)
    public static func encode(_ data: Data) -> String {
        encode(Array(data))
    }

    public static func decodeToData(_ encoded: String) -> Data {
        Data(decode(encoded))
    }
}
