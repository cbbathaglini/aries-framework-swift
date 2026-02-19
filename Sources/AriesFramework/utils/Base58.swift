//
//  Base58.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation

public enum Base58 {
    private static let alphabet = Array("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")
    private static let encodedZero = alphabet[0]
    private static let base = 58

    /// Decodes a Base58-encoded string into a byte array
    public static func decode(_ input: String) throws -> [UInt8] {
        guard !input.isEmpty else {
            return []
        }

        var input58 = [Int](repeating: 0, count: input.count)
        for (i, c) in input.enumerated() {
            guard let index = alphabet.firstIndex(of: c) else {
                throw Base58Error.invalidCharacter(char: c)
            }
            input58[i] = index
        }

        // Count leading zeros
        var zeros = 0
        while zeros < input58.count && input58[zeros] == 0 {
            zeros += 1
        }

        var decoded = [UInt8](repeating: 0, count: input.count)
        var outputStart = decoded.count

        var inputStart = zeros
        while inputStart < input58.count {
            let mod = divmod(&input58, inputStart, 58, 256)
            outputStart -= 1
            decoded[outputStart] = mod
            if input58[inputStart] == 0 {
                inputStart += 1
            }
        }

        // Skip leading zeros in decoded
        while outputStart < decoded.count && decoded[outputStart] == 0 {
            outputStart += 1
        }

        // Add as many leading zeros as there were in the input
        return [UInt8](repeating: 0, count: zeros) + decoded[outputStart...]
    }

    /// Encodes a byte array into a Base58-encoded string
    public static func encode(_ input: [UInt8]) -> String {
        guard !input.isEmpty else {
            return ""
        }

        // Count leading zeros
        var zeros = 0
        while zeros < input.count && input[zeros] == 0 {
            zeros += 1
        }

        var inputCopy = input
        var encoded = [Character](repeating: encodedZero, count: input.count * 2)
        var outputStart = encoded.count

        var inputStart = zeros
        while inputStart < inputCopy.count {
            let mod = divmod(&inputCopy, inputStart, 256, 58)
            outputStart -= 1
            encoded[outputStart] = alphabet[Int(mod)]
            if inputCopy[inputStart] == 0 {
                inputStart += 1
            }
        }

        // Skip leading encoded zeros
        while outputStart < encoded.count && encoded[outputStart] == encodedZero {
            outputStart += 1
        }

        // Add leading encoded zeros
        while zeros > 0 {
            outputStart -= 1
            encoded[outputStart] = encodedZero
            zeros -= 1
        }

        return String(encoded[outputStart...])
    }

    /// Division with remainder, modifying the input array (in-place division)
    private static func divmod(
        _ number: inout [Int],
        _ firstDigit: Int,
        _ base: Int,
        _ divisor: Int
    ) -> UInt8 {
        var remainder = 0
        for i in firstDigit..<number.count {
            let digit = number[i]
            let temp = remainder * base + digit
            number[i] = temp / divisor
            remainder = temp % divisor
        }
        return UInt8(remainder)
    }

    /// Overload for UInt8 arrays (used by encoder)
    private static func divmod(
        _ number: inout [UInt8],
        _ firstDigit: Int,
        _ base: Int,
        _ divisor: Int
    ) -> UInt8 {
        var remainder = 0
        for i in firstDigit..<number.count {
            let digit = Int(number[i])
            let temp = remainder * base + digit
            number[i] = UInt8(temp / divisor)
            remainder = temp % divisor
        }
        return UInt8(remainder)
    }

    enum Base58Error: Error, CustomStringConvertible {
        case invalidCharacter(char: Character)

        var description: String {
            switch self {
            case .invalidCharacter(let char):
                return "Invalid Base58 character: '\(char)'"
            }
        }
    }
}
