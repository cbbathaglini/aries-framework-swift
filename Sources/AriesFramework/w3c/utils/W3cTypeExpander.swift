//
//  W3cTypeExpander.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation

enum W3cTypeExpander {
    
    struct ContextSpec {
        let contexts: [Any?] // [String | [String: Any]]
        let additionalTermMap: [String: String]
        
        init(contexts: [Any?], additionalTermMap: [String: String] = [:]) {
            self.contexts = contexts
            self.additionalTermMap = additionalTermMap
        }
    }

    private static let absoluteIriRegex = try! NSRegularExpression(pattern: #"^[a-zA-Z][a-zA-Z0-9+.-]*:.*"#)

    private static let vcV1Terms: [String: String] = [
        "VerifiableCredential": "https://www.w3.org/2018/credentials#VerifiableCredential",
        "VerifiablePresentation": "https://www.w3.org/2018/credentials#VerifiablePresentation",
        "CredentialStatusList2021": "https://www.w3.org/2018/credentials#CredentialStatusList2021",
        "CredentialSubject": "https://www.w3.org/2018/credentials#CredentialSubject",
        "issuer": "https://www.w3.org/2018/credentials#issuer",
        "issuanceDate": "https://www.w3.org/2018/credentials#issuanceDate",
        "expirationDate": "https://www.w3.org/2018/credentials#expirationDate"
    ]

    public static func expandTypes(spec: ContextSpec, types: [String]) -> [String] {
        let (termMap, prefixMap, vocab) = buildResolutionMaps(contexts: spec.contexts, additionalTermMap: spec.additionalTermMap)

        return types.compactMap { raw in
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { return nil }

            if matchesAbsoluteIri(t) {
                return t
            } else if t.contains(":"), let expanded = expandCurie(t, prefixMap: prefixMap) {
                return expanded
            } else {
                return fallbackTerm(t, termMap: termMap, vocab: vocab)
            }
        }.removingDuplicates()
    }

    private static func buildResolutionMaps(contexts: [Any?], additionalTermMap: [String: String]) -> (termMap: [String: String], prefixMap: [String: String], vocab: String?) {
        var termMap = vcV1Terms.merging(additionalTermMap) { $1 }
        var prefixMap: [String: String] = [:]
        var vocab: String?

        for ctx in contexts {
            if let ctxMap = ctx as? [String: Any] {
                for (key, value) in ctxMap {
                    guard let stringValue = value as? String else { continue }

                    if key == "@vocab" {
                        vocab = stringValue
                    } else if matchesAbsoluteIri(stringValue) {
                        prefixMap[key] = ensureTrailingHashOrSlash(stringValue)
                    } else {
                        // treat as term mapping if absolute IRI
                        if matchesAbsoluteIri(stringValue) {
                            termMap[key] = stringValue
                        }
                    }
                }
            }
        }

        return (termMap, prefixMap, vocab)
    }

    private static func expandCurie(_ curie: String, prefixMap: [String: String]) -> String? {
        let parts = curie.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2, let base = prefixMap[parts[0]] else { return nil }
        return base + parts[1]
    }

    private static func fallbackTerm(_ term: String, termMap: [String: String], vocab: String?) -> String {
        if let resolved = termMap[term] {
            return resolved
        } else if let vocabBase = vocab {
            return ensureTrailingHashOrSlash(vocabBase) + term
        } else {
            return term
        }
    }

    private static func ensureTrailingHashOrSlash(_ input: String) -> String {
        return input.hasSuffix("#") || input.hasSuffix("/") ? input : input + "#"
    }

    private static func matchesAbsoluteIri(_ input: String) -> Bool {
        let range = NSRange(location: 0, length: input.utf16.count)
        return absoluteIriRegex.firstMatch(in: input, options: [], range: range) != nil
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
