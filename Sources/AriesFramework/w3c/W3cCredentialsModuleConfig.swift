//
//  W3cCredentialsModuleConfig.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation

public typealias DocumentLoader = (_ url: String) -> Any?

public struct W3cCredentialsModuleConfigOptions {
    public var documentLoader: DocumentLoader?

    public init(documentLoader: DocumentLoader? = nil) {
        self.documentLoader = documentLoader
    }
}

public class W3cCredentialsModuleConfig {
    private let options: W3cCredentialsModuleConfigOptions

    public init(options: W3cCredentialsModuleConfigOptions = W3cCredentialsModuleConfigOptions()) {
        self.options = options
    }

    public var documentLoader: DocumentLoader {
        return options.documentLoader ?? W3cCredentialsModuleConfig.defaultDocumentLoader
    }

    public static let defaultDocumentLoader: DocumentLoader = { url in
        print("defaultDocumentLoader to \(url)")
        return nil
    }

    public static func loadFile(bundle: Bundle = .main, file: String) throws -> [String: Any] {
        let trimmedPath = file.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        guard let url = bundle.url(forResource: trimmedPath, withExtension: nil) else {
            throw NSError(domain: "W3cCredentialsModuleConfig", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found: \(file)"])
        }

        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data, options: [])

        guard let jsonDict = json as? [String: Any] else {
            throw NSError(domain: "W3cCredentialsModuleConfig", code: 422, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"])
        }

        print("document: \(jsonDict)")
        return jsonDict
    }
}
