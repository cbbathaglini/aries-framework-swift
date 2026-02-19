import Foundation

public class CredentialRepository: Repository<CredentialRecord> {
    public func getByCredentialId(_ credentialId: String) async throws -> CredentialRecord {
        return try await getSingleByQuery("{\"credentialId\": \"\(credentialId)\"}")
    }
    
    public func getByCredentialRevocationIdAndRevocationRegistryId(_ credentialRevocationId: String, _ revocationRegistryId:String) async throws -> CredentialRecord {
       return try await getSingleByQuery("{\"credentialRevocationId\": \(credentialRevocationId)\", \"revocationRegistryId\": \"\(revocationRegistryId)\"}")
   }
    
    public func getByCredentialRevocationId(_ credentialRevocationId: String) async throws -> CredentialRecord {
        return try await getSingleByQuery("{\"credentialRevocationId\": \"\(credentialRevocationId)\"}")
    }
}
