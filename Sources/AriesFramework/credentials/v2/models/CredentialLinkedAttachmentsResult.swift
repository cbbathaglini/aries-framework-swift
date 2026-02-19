//
//  CredentialLinkedAttachmentsResult.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation

struct CredentialLinkedAttachmentsResult: Codable {
    var attachments: [Attachment]?
    var previewAttributes: [CredentialPreviewAttribute]?
}
