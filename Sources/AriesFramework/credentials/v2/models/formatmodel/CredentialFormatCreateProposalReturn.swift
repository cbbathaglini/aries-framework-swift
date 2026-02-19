//
//  CredentialFormatCreateProposalReturn.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

public struct CredentialFormatCreateProposalReturn: Codable {
    public let format: Format
    public let attachment: Attachment
    public let appendAttachment: Attachment?
    public let previewAttribute: [CredentialPreviewAttribute]?

    public init(
        format: Format,
        attachment: Attachment,
        appendAttachment: Attachment? = nil,
        previewAttribute: [CredentialPreviewAttribute]? = []
    ) {
        self.format = format
        self.attachment = attachment
        self.appendAttachment = appendAttachment
        self.previewAttribute = previewAttribute
    }
}
