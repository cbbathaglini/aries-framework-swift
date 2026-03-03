//
//  W3cCredential.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//

import Foundation
import AnyCodable

public struct W3cCredential: Codable, CustomStringConvertible {
    public let context: [AnyCodable]
    public let id: String?
    public let type: [String]
    public let issuer: AnyCodable
    public let issuanceDate: String
    public let credentialSubject: [W3cCredentialSubject]
    public let expirationDate: String?
    public let credentialSchema: [W3cCredentialSchema]?
    public let credentialStatus: W3cCredentialStatus?
    public let proofs: [AnyCodable]?


    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case id, type, issuer, issuanceDate, credentialSubject, expirationDate
        case credentialSchema, credentialStatus, proofs = "proof"
    }

    public var description: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(self), let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        } else {
            return "W3cCredential(invalid JSON)"
        }
    }
    
    public static func fromJson(_ jsonString: String) throws -> W3cCredential {
        let data = Data(jsonString.utf8)
        let decoder = JSONDecoder()
        return try decoder.decode(W3cCredential.self, from: data)
    }

    public static func fromJsonOb(_ jsonString: String) throws -> W3cCredential {
        let root = try parseJsonObject(jsonString)
        let normalized = normalizeIncomingW3cPayload(root: root)
        return try decodeFromJsonObject(normalized)
    }
    
    public static func normalizeIncomingW3cPayload(root: [String: Any]) -> [String: Any] {
        let vcObj: [String: Any]
        if let cred = root["credential"] as? [String: Any] {
            vcObj = cred
        } else {
            vcObj = root
        }

        var mutable = vcObj

        func asArray(_ el: Any?) -> [Any]? {
            guard let el else { return nil }
            if let arr = el as? [Any] { return arr }
            if let obj = el as? [String: Any] { return [obj] }
            return [el]
        }

        func contextAsArray(_ el: Any?) -> [Any]? {
            guard let el else { return nil }
            if let arr = el as? [Any] { return arr }
            if let obj = el as? [String: Any] { return [obj] }
            return [el]
        }

        if let ctx = contextAsArray(mutable["@context"]) {
            mutable["@context"] = ctx
        }

        if let t = asArray(mutable["type"]) {
            mutable["type"] = t
        }

        if let subjectArrayAny = asArray(mutable["credentialSubject"]) {
            let subjects = subjectArrayAny.compactMap { $0 as? [String: Any] }
            var liftedProofs: [[String: Any]] = []
            let cleanedSubjects: [[String: Any]] = subjects.map { subj in
                var subjMap = subj

                if subjMap["id"] != nil && subjMap["@id"] == nil {
                    subjMap["@id"] = subjMap["id"]
                    subjMap.removeValue(forKey: "id")
                }

                if let subjProofArrayAny = asArray(subjMap["proof"]) {
                    let subjProofObjs = subjProofArrayAny.compactMap { $0 as? [String: Any] }
                    if !subjProofObjs.isEmpty {
                        liftedProofs.append(contentsOf: subjProofObjs)
                        subjMap.removeValue(forKey: "proof")
                    }
                }
                return subjMap
            }

            mutable["credentialSubject"] = cleanedSubjects

            let topProofArrayAny = asArray(mutable["proof"]) ?? []
            let topProofObjs = topProofArrayAny.compactMap { $0 as? [String: Any] }

            var finalProofs = topProofObjs + liftedProofs

            var seen = Set<String>()
            finalProofs = finalProofs.filter { proofObj in
                let key = minifiedJSONString(proofObj) ?? UUID().uuidString
                if seen.contains(key) { return false }
                seen.insert(key)
                return true
            }

            if !finalProofs.isEmpty {
                mutable["proof"] = finalProofs
            }
        }

        if let schema = asArray(mutable["credentialSchema"]) {
            mutable["credentialSchema"] = schema
        }

        return mutable
    }

    private static func parseJsonObject(_ jsonString: String) throws -> [String: Any] {
        let data = Data(jsonString.utf8)
        let obj = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dict = obj as? [String: Any] else {
            throw NSError(domain: "W3cCredential", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Expected JSON object at root"
            ])
        }
        return dict
    }

    private static func decodeFromJsonObject(_ obj: [String: Any]) throws -> W3cCredential {
        let data = try JSONSerialization.data(withJSONObject: obj, options: [])
        let decoder = JSONDecoder()
        return try decoder.decode(W3cCredential.self, from: data)
    }

    private static func minifiedJSONString(_ obj: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: obj, options: []) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
