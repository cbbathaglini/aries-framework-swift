//
//  WalletProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//
import Foundation
import askar_uniffi

public protocol WalletProtocol {
    var isInitialized: Bool { get }
    
    // MARK: - Lifecycle

    func initialize() async throws
    func close() async throws
    func delete() async throws

    // MARK: - DID

    var publicDid: DidInfo? { get }
    func initPublicDid(seed: String) async throws
    func createDid(seed: String?) async throws -> (String, String)

    // MARK: - AnonCreds

    var linkSecretId: String? { get }

    // MARK: - DIDComm Crypto

    func pack(
        message: AgentMessage,
        recipientKeys: [String],
        senderVerkey: String?
    ) async throws -> EncryptedMessage

    func unpack(
        encryptedMessage: EncryptedMessage
    ) async throws -> DecryptedMessageContext
    
    func sign(
           data: Data,
           verkey: String
       ) async throws -> Data
    
    
    func getJwkPublic(
        verkey: String
    ) async throws -> [String: Any]

    func verify(
        message: Data,
        signature: Data,
        jwk: String
    ) throws -> Bool

    func verkeyFromJwk(
        jwk: String
    ) throws -> String
    
    func storeLinkSecret(
        id: String,
        value: String,
        category: String
    ) async throws

    func getLinkSecret(
        id: String,
        category: String
    ) async throws -> String
    
    func saveRecord(
        category: String,
        id: String,
        value: Data,
        tags: String?
    ) async throws

    func updateRecord(
        category: String,
        id: String,
        value: Data,
        tags: String?
    ) async throws

    func deleteRecord(
        category: String,
        id: String
    ) async throws

    func fetchRecord(
        category: String,
        id: String
    ) async throws -> AskarEntry?

    func queryRecords(
        category: String,
        query: String
    ) async throws -> [AskarEntry]
}

public extension WalletProtocol {
    
    func createDid(
        seed: String? = nil
    ) async throws -> (String, String) {
        try await createDid()
    }
}

extension Wallet: WalletProtocol {
    
    public func storeLinkSecret(
            id: String,
            value: String,
            category: String
        ) async throws {
            try await session!.update(
                operation: .insert,
                category: category,
                name: id,
                value: value.data(using: .utf8)!,
                tags: nil,
                expiryMs: nil
            )
        }

        public func getLinkSecret(
            id: String,
            category: String
        ) async throws -> String {
            guard let entry = try await session!.fetch(
                category: category,
                name: id,
                forUpdate: false
            ) else {
                throw AriesFrameworkError.recordNotFoundError(
                    "Link secret not found for id \(id)"
                )
            }

            return String(data: entry.value(), encoding: .utf8)!
        }

    public var isInitialized: Bool {
        session != nil
    }
    
    public func sign(
        data: Data,
        verkey: String
    ) async throws -> Data {
        guard let session else {
            throw AriesFrameworkError.frameworkError("Wallet not initialized")
        }

        guard let signKey = try await session.fetchKey(
            name: verkey,
            forUpdate: false
        ) else {
            throw AriesFrameworkError.frameworkError("Key not found: \(verkey)")
        }

        return try signKey
            .loadLocalKey()
            .signMessage(message: data, sigType: nil)
    }
    
    public func getJwkPublic(verkey: String) async throws -> [String: Any] {
        guard let keyEntry = try await session!.fetchKey(name: verkey, forUpdate: false) else {
            throw AriesFrameworkError.frameworkError("Key not found: \(verkey)")
        }
        let key = try keyEntry.loadLocalKey()
        let jwkJson = try key.toJwkPublic(alg: nil)
        guard let data = jwkJson.data(using: .utf8),
              let jwk = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AriesFrameworkError.frameworkError("Invalid JWK")
        }
        return jwk
    }

    public func verify(message: Data, signature: Data, jwk: String) throws -> Bool {
        let key = try keyFactory.fromJwk(jwk: jwk)
        return try key.verifySignature(message: message, signature: signature, sigType: nil)
    }

    public func verkeyFromJwk(jwk: String) throws -> String {
        let key = try keyFactory.fromJwk(jwk: jwk)
        let publicBytes = try key.toPublicBytes()
        return Base58.encode([UInt8](publicBytes))
    }
}
