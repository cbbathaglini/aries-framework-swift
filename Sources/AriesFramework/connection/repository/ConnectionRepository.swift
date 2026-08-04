
import Foundation

public class ConnectionRepository: Repository<ConnectionRecord> {
    
    func findById(connectionId: String?) async throws -> ConnectionRecord? {
        var queryItems: [String: String] = [:]

        if let connectionId = connectionId {
            queryItems["connectionId"] = connectionId
        }

        let query = "{\(queryItems.map { "\"\($0)\": \"\($1)\"" }.joined(separator: ", "))}"

        return try await findSingleByQuery(query)
    }
    
    func deleteById(connectionId: String?) async throws -> ConnectionRecord? {
        var queryItems: [String: String] = [:]

        if let connectionId = connectionId {
            queryItems["connectionId"] = connectionId
        }

        let query = "{\(queryItems.map { "\"\($0)\": \"\($1)\"" }.joined(separator: ", "))}"

        return try await findSingleByQuery(query)
    }
}
