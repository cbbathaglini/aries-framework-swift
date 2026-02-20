//
//  JsonTestEncoder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

import Foundation

enum JsonTestEncoder {

    static func encode(_ value: Any) -> String {
        let data = try! JSONSerialization.data(withJSONObject: value, options: [])
        return String(data: data, encoding: .utf8)!
    }
}
