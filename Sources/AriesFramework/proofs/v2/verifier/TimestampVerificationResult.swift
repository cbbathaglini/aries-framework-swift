//
//  TimestampVerificationResult.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

public struct TimestampVerificationResult: Codable, CustomStringConvertible {
    public var verified: Bool
    public var nonRevokedIntervalOverrides: [NonRevokedIntervalOverride]?

    public init(
        verified: Bool,
        nonRevokedIntervalOverrides: [NonRevokedIntervalOverride]? = nil
    ) {
        self.verified = verified
        self.nonRevokedIntervalOverrides = nonRevokedIntervalOverrides
    }

    public var description: String {
        return "TimestampVerificationResult(verified: \(verified), nonRevokedIntervalOverrides: \(String(describing: nonRevokedIntervalOverrides)))"
    }
}
