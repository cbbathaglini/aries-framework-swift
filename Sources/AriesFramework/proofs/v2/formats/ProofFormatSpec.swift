//
//  ProofFormatSpec.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/10/25.
//

import Foundation

public struct ProofFormatSpec: Codable, CustomStringConvertible {
    public let attachmentId: String?
    public let format: String

    public init(attachmentId: String?, format: String) {
        self.attachmentId = attachmentId != nil ? attachmentId : RecordUtils.generateId()
        self.format = format
    }

    enum CodingKeys: String, CodingKey {
        case attachmentId = "attach_id"
        case format
    }
    
    public var description: String {
            if let id = attachmentId {
                return "\(format) (attach_id: \(id))"
            } else {
                return format
            }
        }
}
