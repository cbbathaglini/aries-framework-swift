//
//  FlexibleDate.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 14/10/25.
//
import Foundation

public struct FlexibleDate: Codable {
    public var date: Date

    public init(_ date: Date) {
        self.date = date
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()


        if let timestamp = try? container.decode(Double.self) {
            self.date = Date(timeIntervalSince1970: timestamp)
            return
        }

        if let dateString = try? container.decode(String.self) {
            let formatter = ISO8601DateFormatter()
            if let parsed = formatter.date(from: dateString) {
                self.date = parsed
                return
            }
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Invalid date format (expected timestamp or ISO8601 string)."
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(date.timeIntervalSince1970)
    }
}
