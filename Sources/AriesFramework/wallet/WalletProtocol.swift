////
////  WalletProtocol.swift
////  aries-framework-swift
////
////  Created by Carine Bertagnolli Bathaglini on 19/12/25.
////
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

    // MARK: - Crypto helpers

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

    // MARK: - Link secret helpers

    func storeLinkSecret(
        id: String,
        value: String,
        category: String
    ) async throws

    func getLinkSecret(
        id: String,
        category: String
    ) async throws -> String

    // MARK: - Generic record operations

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


