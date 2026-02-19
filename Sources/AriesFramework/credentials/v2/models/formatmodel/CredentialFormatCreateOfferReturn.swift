//
//  CredentialFormatCreateOfferReturn.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

public struct CredentialFormatCreateOfferReturn: Codable {
    public let attachment: Attachment
    public let format: Format
    public let previewAttributes: [CredentialPreviewAttribute]

    public init(
        attachment: Attachment,
        format: Format,
        previewAttributes: [CredentialPreviewAttribute]
    ) {
        self.attachment = attachment
        self.format = format
        self.previewAttributes = previewAttributes
    }
}
