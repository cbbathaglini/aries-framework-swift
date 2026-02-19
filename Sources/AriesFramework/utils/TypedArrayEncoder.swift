//
//  TypedArrayEncoder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation

public struct TypedArrayEncoder {
    public static func fromBase64(_ base64: String) -> [UInt8] {
        guard let data = Data(base64Encoded: base64) else {
            fatalError("Invalid Base64 data")
        }
        return [UInt8](data)
    }
}
