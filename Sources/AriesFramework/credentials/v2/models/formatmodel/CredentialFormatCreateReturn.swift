//
//  CredentialFormatCreateReturn.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

public struct CredentialFormatCreateReturn: Codable, CustomStringConvertible {
    public let attachment: Attachment
    public let format: Format
    public let appendAttachment: [Attachment]?

    public init(
        attachment: Attachment,
        format: Format,
        appendAttachment: [Attachment]? = []
    ) {
        self.attachment = attachment
        self.format = format
        self.appendAttachment = appendAttachment
    }
    
    public var description: String {
        return """
        CredentialFormatCreateReturn(
          attachment: \(attachment),
          format: \(format),
          appendAttachment: \(appendAttachment ?? [])
        )
        """
    }
}
