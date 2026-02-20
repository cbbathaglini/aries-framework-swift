//
//  FormatTestFactory.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework
import Foundation

enum FormatTestFactory {

    // MARK: - Common formats

    static func anoncreds(
        attachId: String = AttachmentTestFactory.defaultAttachmentId
    ) -> Format {
        return Format(
            attachId: attachId,
            format: "anoncreds"
        )
    }

    static func indy(
        attachId: String = AttachmentTestFactory.defaultAttachmentId
    ) -> Format {
        return Format(
            attachId: attachId,
            format: "libindy-cred-request-0"
        )
    }

    static func jsonLd(
        attachId: String = AttachmentTestFactory.defaultAttachmentId
    ) -> Format {
        return Format(
            attachId: attachId,
            format: "json-ld" ///revisar
        )
    }

    // MARK: - Generic / Custom

    static func custom(
        format: String,
        attachId: String = UUID().uuidString
    ) -> Format {
        return Format(
            attachId: attachId,
            format: format
        )
    }
}
