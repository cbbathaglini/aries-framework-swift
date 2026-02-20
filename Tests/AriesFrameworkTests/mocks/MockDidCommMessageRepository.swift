//
//  MockDidCommMessageRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework
import Foundation

final class MockDidCommMessageRepository: DidCommMessageRepository {

    private var store: [DidCommKey: DidCommMessageRecord] = [:]
    private var fallbackStore: [DidCommMessageRecord] = []

    // MARK: - Helpers

    private func normalizeType(_ type: String) -> String {
        if agent.agentConfig.useLegacyDidSovPrefix {
            return Dispatcher.replaceNewDidCommPrefixWithLegacyDidSov(
                messageType: type
            )
        }
        return type
    }

    private func makeKey(
        associatedRecordId: String,
        messageType: String,
        role: DidCommMessageRole?
    ) -> DidCommKey {
        DidCommKey(
            associatedRecordId: associatedRecordId,
            messageType: normalizeType(messageType),
            role: role
        )
    }

    // MARK: - Overrides fundamentais

    override func save(_ record: DidCommMessageRecord) async throws {
        fallbackStore.append(record)
    }

    override func update(_ record: DidCommMessageRecord) async throws {
        guard let existingKey = store.keys.first(where: {
            $0.associatedRecordId == record.associatedRecordId &&
            $0.role == record.role
        }) else {
            throw AriesFrameworkError.recordNotFoundError(
                "DidCommMessageRecord not found for update"
            )
        }

        store[existingKey] = record
    }

    override func findSingleByQuery(_ query: String) async throws -> DidCommMessageRecord? {
        return store.values.first
    }

    override func getSingleByQuery(_ query: String) async throws -> DidCommMessageRecord {
        guard let record = store.values.first else {
            throw AriesFrameworkError.recordNotFoundError("DidCommMessage not found")
        }
        return record
    }

    // MARK: - API real espelhada

    override func saveAgentMessage(
        role: DidCommMessageRole,
        agentMessage: AgentMessage,
        associatedRecordId: String
    ) async throws {
        let normalizedType = normalizeType(agentMessage.type)

        let record = try DidCommMessageRecord(
            message: agentMessage,
            role: role,
            associatedRecordId: associatedRecordId
        )

        let key = makeKey(
            associatedRecordId: associatedRecordId,
            messageType: normalizedType,
            role: role
        )

        store[key] = record
    }

    override func saveOrUpdateAgentMessage(
        role: DidCommMessageRole,
        agentMessage: AgentMessage,
        associatedRecordId: String
    ) async throws {
        let normalizedType = normalizeType(agentMessage.type)

        let key = makeKey(
            associatedRecordId: associatedRecordId,
            messageType: normalizedType,
            role: role
        )

        if var existing = store[key] {
            existing.message = try agentMessage.toJsonString()
            existing.role = role
            store[key] = existing
            return
        }

        try await saveAgentMessage(
            role: role,
            agentMessage: agentMessage,
            associatedRecordId: associatedRecordId
        )
    }

    override func getAgentMessage(
        associatedRecordId: String,
        messageType: String
    ) async throws -> String {

        let normalizedType = normalizeType(messageType)

        guard let record = store.first(where: { (key, _) in
            key.associatedRecordId == associatedRecordId &&
            normalizeType(key.messageType) == normalizedType
        })?.value else {
            throw AriesFrameworkError.recordNotFoundError("Message not found")
        }

        return record.message
    }

    override func getAgentMessage(
        associatedRecordId: String,
        messageType: String,
        role: DidCommMessageRole
    ) async throws -> String? {
        let key = makeKey(
            associatedRecordId: associatedRecordId,
            messageType: messageType,
            role: role
        )

        return store[key]?.message
    }

    override func findAgentMessage(
        associatedRecordId: String,
        messageType: String
    ) async throws -> String? {

        let normalizedType = normalizeType(messageType)

        return store.first { (key, _) in
            key.associatedRecordId == associatedRecordId &&
            normalizeType(key.messageType) == normalizedType
        }?.value.message
    }

    override func getTypedAgentMessage<T: Decodable>(
        associatedRecordId: String,
        messageType: String,
        role: DidCommMessageRole
    ) async throws -> T? {
        let key = makeKey(
            associatedRecordId: associatedRecordId,
            messageType: messageType,
            role: role
        )

        guard let record = store[key],
              let data = record.message.data(using: .utf8) else {
            return nil
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
    
}


private struct DidCommKey: Hashable {
    let associatedRecordId: String
    let messageType: String
    let role: DidCommMessageRole?
}
