
import Foundation

public class MediationRepository: Repository<MediationRecord> {
    func getByConnectionId(_ connectionId: String) async throws -> MediationRecord {
        let query = "{\"connectionId\": \"\(connectionId)\"}"
        return try await getSingleByQuery(query)
    }

    func getDefault() async throws -> MediationRecord? {
        let query = "{}"
        return try await findSingleByQuery(query)
    }
}
