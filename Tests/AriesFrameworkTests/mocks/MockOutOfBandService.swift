//
//  MockOutOfBandService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

@testable import AriesFramework

final class MockOutOfBandService: OutOfBandServiceProtocol {

    var recordsByInvitationKey: [String: [OutOfBandRecord]] = [:]
    var recordsById: [String: OutOfBandRecord] = [:]

    // MARK: - Process incoming messages

    func processHandshakeReuse(
        messageContext: InboundMessageContext
    ) async throws -> HandshakeReuseAcceptedMessage {
        fatalError("Not implemented in mock")
    }

    func processHandshakeReuseAccepted(
        messageContext: InboundMessageContext
    ) async throws {
        fatalError("Not implemented in mock")
    }

    // MARK: - Create messages

    func createHandShakeReuse(
        outOfBandRecord: OutOfBandRecord,
        connectionRecord: ConnectionRecord
    ) async throws -> HandshakeReuseMessage {
        fatalError("Not implemented in mock")
    }

    // MARK: - Persistence helpers

    func save(
        outOfBandRecord: OutOfBandRecord
    ) async throws {
        recordsById[outOfBandRecord.id] = outOfBandRecord
    }

    func findById(
        _ outOfBandRecordId: String
    ) async throws -> OutOfBandRecord? {
        recordsById[outOfBandRecordId]
    }

    func getById(
        _ outOfBandRecordId: String
    ) async throws -> OutOfBandRecord {
        guard let record = recordsById[outOfBandRecordId] else {
            throw AriesFrameworkError.frameworkError("OutOfBandRecord not found")
        }
        return record
    }

    func findByInvitationId(
        _ invitationId: String
    ) async throws -> OutOfBandRecord? {
        recordsById.values.first {
            $0.outOfBandInvitation.id == invitationId
        }
    }

    func findAllByInvitationKey(
        _ invitationKey: String
    ) async -> [OutOfBandRecord] {
        recordsByInvitationKey[invitationKey] ?? []
    }

    func findByFingerprint(_ fingerprint: String) async throws -> OutOfBandRecord? {
        for record in recordsById.values {
            let tags = record.getTags()

            // tags["recipientKeyFingerprints"] normalmente é uma String JSON ou CSV
            if let fingerprints = tags["recipientKeyFingerprints"],
               fingerprints.contains(fingerprint) {
                return record
            }
        }
        return nil
    }

    func getAll() async -> [OutOfBandRecord] {
        Array(recordsById.values)
    }

    func deleteById(
        _ outOfBandId: String
    ) async throws {
        recordsById.removeValue(forKey: outOfBandId)
    }

    func waitForHandshakeReuse() async throws -> Bool {
        return true
    }

    func updateState(
        outOfBandRecord: inout OutOfBandRecord,
        newState: OutOfBandState
    ) async throws {
        outOfBandRecord.state = newState
        recordsById[outOfBandRecord.id] = outOfBandRecord
    }
}
