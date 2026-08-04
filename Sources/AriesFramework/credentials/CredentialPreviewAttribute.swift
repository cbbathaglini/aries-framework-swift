
import Foundation

public struct CredentialPreviewAttribute : Codable {
    public var name: String
    public var mimeType: String?
    public var value: String
    
    init(name: String, mimeType: String, value: String) {
        self.name = name
        self.mimeType = mimeType
        self.value = value
    }
    
    init<O: CredentialPreviewAttributeOptions>(_ options: O) {
        self.name = options.name
        self.mimeType = options.mimeType
        self.value = options.value
    }
}

extension CredentialPreviewAttribute {
    enum CodingKeys: String, CodingKey {
        case name, mimeType = "mime-type", value
    }
    
    public func toMap() -> [String: Any?] {
        return [
            "name": self.name,
            "mimeType": self.mimeType,
            "value": self.value
        ]
    }
}
