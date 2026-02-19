//
//  Format.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/25.
//

public struct Format: Codable {
    public var attachId: String
    public var format: String

    enum CodingKeys: String, CodingKey {
        case attachId = "attach_id"
        case format
    }
    
    public init(attachId: String, format: String) {
        self.attachId = attachId
        self.format = format
    }
    
    public init(format: String) {
        self.attachId = CredentialExchangeRecord.generateId()
        self.format = format
    }

    public init(options: FormatSpec) {
        self.attachId = options.attachmentId
        self.format = options.format
    }
    
    /// Custom `description` to mimic `toString()` in Kotlin
    public var description: String {
        return "Format(attachId=\(String(describing: attachId)), format='\(format)')"
    }
}
