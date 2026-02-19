//
//  AckDecorator.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/25.
//

import Foundation

public struct AckDecorator: Codable, CustomStringConvertible {
    public var on: [AckValues]

    public init(on: [AckValues] = [.receipt]) {
        self.on = on
    }

    public init(options: [String: [AckValues]]) {
        self.on = options["on"] ?? [.receipt]
    }

    public func isNotEmpty() -> Bool {
        return !on.isEmpty
    }
    
    public var description: String {
        return "AckDecorator(on: \(on))"
    }
}
