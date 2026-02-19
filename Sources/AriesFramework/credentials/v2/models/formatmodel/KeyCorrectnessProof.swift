//
//  KeyCorrectnessProof.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

struct KeyCorrectnessProof: Codable, CustomStringConvertible {
    let c: String
    let xzCap: String
    let xrCap: [[String]]

    enum CodingKeys: String, CodingKey {
        case c
        case xzCap = "xz_cap"
        case xrCap = "xr_cap"
    }

    var description: String {
        return "KeyCorrectnessProof(c='\(c)', xz_cap='\(xzCap)', xr_cap=\(xrCap))"
    }
}
