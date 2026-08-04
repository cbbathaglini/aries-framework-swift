
import Foundation
import AnyCodable

public class ProofRepository: Repository<ProofExchangeRecord> {
    public func getByThreadAndConnectionId(threadId: String, connectionId: String?) async throws -> ProofExchangeRecord {
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
    
    public func getByConnectionId(connectionId: String?) async throws -> ProofExchangeRecord {
        return try await getSingleByQuery("""
            {"connectionId": "\(connectionId)"}
            """
        )
    }
    
    /**
     Finds a `ProofExchangeRecord` by optional thread ID, role, and connection ID.

     - Parameters:
        - threadId: The thread identifier of the proof exchange.
        - role: The role in the proof exchange (e.g., Prover, Verifier).
        - connectionId: The connection identifier associated with the proof.

     - Returns: A matching `ProofExchangeRecord` if found, otherwise `nil`.
     */
    public func findByThreadRoleAndConnection(
        threadId: String? = nil,
        role: ProofRole? = nil,
        connectionId: String? = nil
    ) async throws -> ProofExchangeRecord? {
        
        var queryObj: [String: AnyCodable] = [:]

        if let threadId = threadId, !threadId.isEmpty {
            queryObj["threadId"] = AnyCodable(threadId)
        }

        if let connectionId = connectionId, !connectionId.isEmpty {
            queryObj["connectionId"] = AnyCodable(connectionId)
        }

        if let roleName = role?.rawValue {
            queryObj["role"] = AnyCodable(roleName)
        }

        if queryObj.isEmpty {
            return nil
        }

        let queryJsonData = try JSONEncoder().encode(queryObj)
        guard let queryJsonString = String(data: queryJsonData, encoding: .utf8) else {
            throw CredoError("Failed to encode query object")
        }

        return try await getSingleByQuery(queryJsonString)
    }
    
    func getByThreadAndConnectionIdAndRole(
        threadId: String?,
        connectionId: String?,
        role: String
    ) async throws -> ProofExchangeRecord? {
        var queryDict: [String: String] = [:]

        if let threadId = threadId, !threadId.isEmpty {
            queryDict["threadId"] = threadId
        }

        if let connectionId = connectionId, !connectionId.isEmpty {
            queryDict["connectionId"] = connectionId
        }

        queryDict["role"] = role

        let jsonData = try JSONSerialization.data(withJSONObject: queryDict, options: [])
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw CredoError("Failed to serialize query object")
        }

        return try await findSingleByQuery(jsonString)
    }
    
    public func getByPresentationMessageId(_ messageId: String) async throws -> ProofExchangeRecord? {
        let query = """
        { "presentationMessage.id": "\(messageId)" }
        """

       return try await findSingleByQuery(query)
    }
}

