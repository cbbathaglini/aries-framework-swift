
import Foundation

public struct AttachmentData: Codable, CustomStringConvertible {
    var base64: String?
    var json: String?
    var links: [String]?
    var jws: Jws?
    var sha256: String?

    enum CodingKeys: String, CodingKey {
        case base64, json, links, jws, sha256
    }
    
    public var description: String {
        var parts: [String] = []
        if let base64 = base64 {
            parts.append("base64: \(base64.prefix(20))...")
        }
        if let json = json {
            parts.append("json: \(json.prefix(50))...")
        }
        if let links = links {
            parts.append("links: \(links)")
        }
        if let jws = jws {
            parts.append("jws: \(jws)")
        }
        if let sha256 = sha256 {
            parts.append("sha256: \(sha256)")
        }
        return "{ " + parts.joined(separator: ", ") + " }"
    }
}

public struct Attachment: Codable, CustomStringConvertible {
    var id: String
    var desc: String?
    var filename: String?
    var mimetype: String?
    var lastModified: Date?
    var byteCount: Int?
    var data: AttachmentData

    enum CodingKeys: String, CodingKey {
        case id = "@id", desc = "description", filename, mimetype = "mime-type", lastModified = "lastmod_time", byteCount = "byte_count", data
    }

    public func getDataAsString() throws -> String {
        if let base64 = data.base64, let decoded = Data(base64Encoded: base64) {
            return String(data: decoded, encoding: .utf8)!
        } else if let json = data.json {
        
            return json
        } else {
            throw AriesFrameworkError.frameworkError("No attachment data found in `json` or `base64` data fields.")
        }
    }
    
    func getDataAsJson() throws -> String {
        if let base64 = data.base64 {
            guard let decodedData = Data(base64Encoded: base64),
                  let decodedString = String(data: decodedData, encoding: .utf8) else {
                throw CredoError("Failed to decode base64 attachment data.")
            }
            return decodedString
        } else if let json = data.json {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw CredoError("Failed to encode JSON data to string.")
            }
            return jsonString
        } else {
            throw CredoError("No attachment data found in `json` or `base64` data fields.")
        }
    }

    mutating func addJws(_ jws: JwsGeneralFormat) {
        if data.jws == nil {
            data.jws = .general(jws)
            return
        }

        switch data.jws {
        case .flattened(var flattened):
            flattened.signatures.append(jws)
        case .general(let general):
            data.jws = .flattened(JwsFlattenedFormat(signatures: [general, jws]))
        case .none: break
        }
    }

    public static func fromData(_ data: Data, id: String = UUID().uuidString) -> Attachment {
        return Attachment(
            id: id,
            mimetype: "application/json",
            data: AttachmentData(base64: data.base64EncodedString()))
    }

    public var description: String {
        return """
        Attachment(
          id: \(id),
          filename: \(filename ?? "nil"),
          mimetype: \(mimetype ?? "nil"),
          description: \(desc ?? "nil"),
          byteCount: \(byteCount?.description ?? "nil"),
          lastModified: \(lastModified?.description ?? "nil"),
          data: \(data)
        )
        """
    }
}

