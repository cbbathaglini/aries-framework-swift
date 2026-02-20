//
//  CredentialPreviewAttributeBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework
import Foundation

final class CredentialPreviewAttributeBuilder {

    private var name: String = "attr"
    private var value: String = "value"
    private var mimeType: String = "text/plain"

    func withName(_ name: String) -> Self {
        self.name = name
        return self
    }

    func withValue(_ value: String) -> Self {
        self.value = value
        return self
    }

    func withMimeType(_ mimeType: String) -> Self {
        self.mimeType = mimeType
        return self
    }

    func build() -> CredentialPreviewAttribute {
        CredentialPreviewAttribute(
            name: name,
            mimeType: mimeType,
            value: value
        )
    }
}
