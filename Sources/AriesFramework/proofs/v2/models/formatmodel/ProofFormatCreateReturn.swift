//
//  ProofFormatCreateReturn.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

import Foundation

public struct ProofFormatCreateReturn: Codable, CustomStringConvertible {
    public let format: ProofFormatSpec
    public let attachment: Attachment

    public init(format: ProofFormatSpec, attachment: Attachment) {
        self.format = format
        self.attachment = attachment
    }
    
    public var description: String {
            return "ProofFormatCreateReturn(format: \(format), attachment: \(attachment))"
        }
}
