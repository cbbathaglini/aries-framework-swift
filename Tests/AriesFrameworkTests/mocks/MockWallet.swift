//
//  MockWallet.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

@testable import AriesFramework
import Foundation
import askar_uniffi

final class MockWallet: WalletProtocol {

    // MARK: - State

    var publicDid: DidInfo?
    var linkSecretId: String?
    var isInitialized: Bool = true

    // storage simples em memória
    private var records: [String: [String: Data]] = [:]
    private var linkSecrets: [String: String] = [:]

    // MARK: - Lifecycle

    func initialize() async throws {
        isInitialized = true
    }

    func close() async throws {
        isInitialized = false
    }

    func delete() async throws {
        records.removeAll()
        linkSecrets.removeAll()
    }

    // MARK: - DID

    func initPublicDid(seed: String) async throws {
        publicDid = DidInfo(did: "did:test", verkey: "verkey")
    }

    func createDid(seed: String?) async throws -> (String, String) {
        return ("did:test", "verkey")
    }

    // MARK: - DIDComm Crypto (stubs)

    func pack(
        message: AgentMessage,
        recipientKeys: [String],
        senderVerkey: String?
    ) async throws -> EncryptedMessage {
        fatalError("pack not needed in unit tests")
    }

    func unpack(
        encryptedMessage: EncryptedMessage
    ) async throws -> DecryptedMessageContext {
        fatalError("unpack not needed in unit tests")
    }

    func sign(
        data: Data,
        verkey: String
    ) async throws -> Data {
        return Data("signed".utf8)
    }

    func verify(
        message: Data,
        signature: Data,
        jwk: String
    ) throws -> Bool {
        return true
    }

    func getJwkPublic(
        verkey: String
    ) async throws -> [String: Any] {
        return [
            "kty": "OKP",
            "crv": "Ed25519",
            "x": "test"
        ]
    }

    func verkeyFromJwk(
        jwk: String
    ) throws -> String {
        return "verkey"
    }

    // MARK: - AnonCreds

    func storeLinkSecret(
        id: String,
        value: String,
        category: String
    ) async throws {
        linkSecrets[id] = value
    }

    func getLinkSecret(
        id: String,
        category: String
    ) async throws -> String {
        guard let value = linkSecrets[id] else {
            throw AriesFrameworkError.recordNotFoundError("Link secret not found")
        }
        return value
    }

    // MARK: - Repository helpers (mock Askar)

    func saveRecord(
        category: String,
        id: String,
        value: Data,
        tags: String?
    ) async throws {
        records[category, default: [:]][id] = value
    }

    func updateRecord(
        category: String,
        id: String,
        value: Data,
        tags: String?
    ) async throws {
        records[category, default: [:]][id] = value
    }

    func deleteRecord(
        category: String,
        id: String
    ) async throws {
        records[category]?[id] = nil
    }

    func fetchRecord(
        category: String,
        id: String
    ) async throws -> AskarEntry? {
        return nil
    }

    func queryRecords(
        category: String,
        query: String
    ) async throws -> [AskarEntry] {
        return []
    }
}
