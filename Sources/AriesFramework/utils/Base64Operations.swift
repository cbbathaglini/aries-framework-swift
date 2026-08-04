//
//  Base64Operations.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation


public func fromBase64ToString(_ base64Str: String?) -> String {
    guard let base64Str = base64Str,
          let data = Data(base64Encoded: base64Str) else {
        return ""
    }
    return String(data: data, encoding: .utf8) ?? ""
}

