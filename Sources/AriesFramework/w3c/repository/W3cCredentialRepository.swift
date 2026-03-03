//
//  W3cCredentialRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//

import Foundation

public final class W3cCredentialRepository: Repository<W3cCredentialRecord> {

    // MARK: - Find by subject id (Kotlin-like)

    public func findByCredentialSubjectId(_ subjectId: String) async throws -> [W3cCredentialRecord] {
        let sid = subjectId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sid.isEmpty else { return [] }

        let byFixed = await findByQuery("{\"subjectId\": \"\(escapeJSON(sid))\"}")
        if !byFixed.isEmpty { return byFixed }

        let key = "subjectId:\(sid)"
        let byDynamic = await findByQuery("{\"\(escapeJSON(key))\": \"1\"}")
        if !byDynamic.isEmpty { return byDynamic }

        let all = await getAll()
        return all.filter { record in
            record.credential.credentialSubject.contains { subj in
                subj.id?.trimmingCharacters(in: .whitespacesAndNewlines) == sid
            }
        }
    }

    // MARK: - Helpers

    private func escapeJSON(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}
