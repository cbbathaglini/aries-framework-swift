//
//  W3cTypeExpander.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation
import AnyCodable
import JSONLD

/// Expands the "type" values of a W3C VC using the JSONLD library.
///
/// Equivalent to credo-ts `jsonld.expand()` (and the Kotlin `W3cTypeExpander`,
/// which delegates to jsonld-java). Remote contexts are resolved over HTTP by
/// the JSONLD library itself.
enum W3cTypeExpander {

    struct ContextSpec {
        let contexts: [AnyCodable]
        let additionalTermMap: [String: String]

        init(contexts: [AnyCodable], additionalTermMap: [String: String] = [:]) {
            self.contexts = contexts
            self.additionalTermMap = additionalTermMap
        }
    }

    /// Expands the given types using the document's @context.
    public static func expandTypes(spec: ContextSpec, types: [String]) -> [String] {
        print("🔍 DIAG [W3C] expandTypes - entrada types=\(types) contexts=\(spec.contexts)")
        // Build the input document: { "@context": [...], "type": [...] }
        let contextValue: Any = spec.contexts.map { $0.value }
        var document: [String: Any] = [
            "@context": contextValue,
            "type": types,
        ]

        // Optionally merge additional terms into the inline context.
        if !spec.additionalTermMap.isEmpty {
            var contexts = spec.contexts.map { $0.value }
            var inlineContext = contexts.first as? [String: Any] ?? [:]
            inlineContext.merge(spec.additionalTermMap) { $1 }
            if contexts.isEmpty {
                contexts.append(inlineContext)
            } else {
                contexts[0] = inlineContext
            }
            document["@context"] = contexts
        }

        print("🔍 DIAG [W3C] expandTypes - documento=\(document)")
        do {
            let expanded = try JSONLD().expand(data: JSON.wrap(document))
            let result = extractTypes(from: expanded)
            print("🔍 DIAG [W3C] expandTypes - tipos expandidos=\(result)")
            return result
        } catch {
            print("🔍 DIAG [W3C] expandTypes - ERRO ao expandir: \(error)")
            print("🔍 DIAG [W3C] expandTypes - tentando fallback com contexto inline minimo")
            return fallbackExpandTypes(types: types)
        }
    }

    private static func fallbackExpandTypes(types: [String]) -> [String] {
        // The remote contexts (e.g. w3.org/credentials/v1) use @protected terms that this
        // JSON-LD library fails to process. Fall back to an inline context mapping the
        // common V1 terms so the @type is not lost.
        let inlineContext: [String: Any] = [
            "type": "@type",
            "id": "@id",
            "VerifiableCredential": "https://www.w3.org/2018/credentials#VerifiableCredential",
            "VerifiablePresentation": "https://www.w3.org/2018/credentials#VerifiablePresentation",
            "CredentialSubject": "https://www.w3.org/2018/credentials#CredentialSubject",
            "issuer": "https://www.w3.org/2018/credentials#issuer",
            "issuanceDate": "https://www.w3.org/2018/credentials#issuanceDate",
            "expirationDate": "https://www.w3.org/2018/credentials#expirationDate",
        ]
        let doc: [String: Any] = ["@context": inlineContext, "type": types]
        guard let expanded = try? JSONLD().expand(data: JSON.wrap(doc)) else {
            return []
        }
        return extractTypes(from: expanded)
    }

    /// Extracts the expanded `@type` values from the JSON-LD expansion result.
    private static func extractTypes(from expanded: JSON) -> [String] {
        // The expansion result is an array of node objects; read the first node's "@type".
        guard let firstNode = expanded[0] else {
            return []
        }

        guard let typeValue = firstNode["@type"] else {
            return []
        }

        var result: [String] = []
        switch typeValue.value {
        case .string(let s):
            result.append(s)
        case .array(let items):
            for item in items {
                if case .string(let s) = item.value {
                    result.append(s)
                }
            }
        default:
            break
        }

        return Array(Set(result))
    }
}
