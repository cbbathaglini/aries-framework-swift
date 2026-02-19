//
//  CredentialPreviewV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

public struct CredentialPreviewV2: Codable {
    var attributes: [CredentialPreviewAttribute]


    enum CodingKeys: String, CodingKey {
        case attributes
        case type = "@type"
    }

    let type: String = CredentialsConstants.CREDENTIAL_PREVIEW_V2

    init(options: any CredentialPreviewOptions) {
        self.attributes = options.attributes.map { CredentialPreviewAttribute($0) }
    }

    init(attributes: [CredentialPreviewAttribute]) {
        self.attributes = attributes
    }

    func toJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func fromDictionary(_ record: [String: String]) -> CredentialPreviewV2 {
        let attributes = record.map { (name, value) in
            CredentialPreviewAttribute(name: name, mimeType: "text/plain", value: value)
        }
        return CredentialPreviewV2(attributes: attributes)
    }
}
