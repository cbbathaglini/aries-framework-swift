//
//  RevocationNotification.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/25.
//

import Foundation

public struct RevocationNotification: Codable {
    public var comment: String?
    public var revocationDate: Date

    public init(comment: String? = nil, revocationDate: Date = Date()) {
        self.comment = comment
        self.revocationDate = revocationDate
    }
    
    public func toMap() -> [String: Any?] {
        return [
            "revocationDate": String.fromDate(self.revocationDate), // Adapte para .toInstant() se necessário
            "comment": self.comment
        ]
    }
}
