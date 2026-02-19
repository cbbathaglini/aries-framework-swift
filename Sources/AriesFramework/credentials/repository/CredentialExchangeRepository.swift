
import Foundation

public class CredentialExchangeRepository: Repository<CredentialExchangeRecord> {
    public func findByThreadAndConnectionId(threadId: String, connectionId: String?) async throws -> CredentialExchangeRecord? {
        if let connectionId = connectionId {
            return try await findSingleByQuery("""
                {"threadId": "\(threadId)",
                "connectionId": "\(connectionId)"}
                """
            )
        } else {
            return try await findSingleByQuery("""
                {"threadId": "\(threadId)"}
                """
            )
        }
    }
    
    public func getByW3cCredentialId(_ w3cId: String) async throws -> CredentialExchangeRecord {
        let all = try await getAll()

        if let record = all.first(where: { record in
            record.credentials.contains(where: { $0.credentialRecordId == w3cId })
        }) {
            return record
        }

        throw CredoError("Credential not found for w3cCredentialId=\(w3cId)")
    }

    public func getByThreadAndConnectionId(threadId: String, connectionId: String?) async throws -> CredentialExchangeRecord {
        if let connectionId = connectionId {
            return try await getSingleByQuery("""
                {"threadId": "\(threadId)",
                "connectionId": "\(connectionId)"}
                """
            )
        } else {
            return try await getSingleByQuery("""
                {"threadId": "\(threadId)"}
                """
            )
        }
    }
    
    func getByThreadAndRole(threadId: String, role: CredentialRole?) async throws -> CredentialExchangeRecord? {
        let roleString = role?.rawValue ?? ""
        let query = """
        {
            "threadId": "\(threadId)",
            "role": "\(roleString)"
        }
        """
        return try await getSingleByQuery(query)
    }

    func getByThreadAndRoleAndConnectionId(threadId: String, role: String?, connectionId: String?) async throws -> CredentialExchangeRecord? {
        let roleValue = role ?? ""
        let connValue = connectionId ?? ""
        let query = """
        {
            "threadId": "\(threadId)",
            "connectionId": "\(connValue)",
            "role": "\(roleValue)"
        }
        """
        return try await getSingleByQuery(query)
    }

    func findByThreadRoleAndConnectionId(threadId: String, role: CredentialRole?, connectionId: String?) async throws -> CredentialExchangeRecord? {
        var queryItems: [String: String] = ["threadId": threadId]

        if let connectionId = connectionId {
            queryItems["connectionId"] = connectionId
        }

        if let role = role {
            queryItems["role"] = role.rawValue
        }

        let query = "{\(queryItems.map { "\"\($0)\": \"\($1)\"" }.joined(separator: ", "))}"

        return try await findSingleByQuery(query)
    }
    
    public func getByCredentialRevocationId(_ credentialRevocationId: String) async throws -> CredentialExchangeRecord {
        return try await getSingleByQuery("{\"credRevId\": \"\(credentialRevocationId)\"}")
    }
    
    public func getByCredentialRevocationIdAndRevocationRegistryId(
        credentialRevocationId: String,
        revocationRegistryId: String,
        anoncredsType: Bool
    ) async throws -> CredentialExchangeRecord {
        if !anoncredsType {
            return try await getSingleByQuery("""
            {"credRevId": "\(credentialRevocationId)", "revocationRegistryId": "\(revocationRegistryId)"}
            """)
        }

        return try await getSingleByQuery("""
        {"anonCredsCredentialRevocationId": "\(credentialRevocationId)", "anonCredsRevocationRegistryId": "\(revocationRegistryId)"}
        """)
    }
}
