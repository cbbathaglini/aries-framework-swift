//
//  OutOfBandServiceProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

public protocol OutOfBandServiceProtocol: AnyObject {

    // MARK: - Process incoming messages

    func processHandshakeReuse(
        messageContext: InboundMessageContext
    ) async throws -> HandshakeReuseAcceptedMessage

    func processHandshakeReuseAccepted(
        messageContext: InboundMessageContext
    ) async throws

    // MARK: - Create messages

    func createHandShakeReuse(
        outOfBandRecord: OutOfBandRecord,
        connectionRecord: ConnectionRecord
    ) async throws -> HandshakeReuseMessage

    // MARK: - Persistence helpers

    func save(
        outOfBandRecord: OutOfBandRecord
    ) async throws

    func findById(
        _ outOfBandRecordId: String
    ) async throws -> OutOfBandRecord?

    func getById(
        _ outOfBandRecordId: String
    ) async throws -> OutOfBandRecord

    func findByInvitationId(
        _ invitationId: String
    ) async throws -> OutOfBandRecord?

    func findAllByInvitationKey(
        _ invitationKey: String
    ) async -> [OutOfBandRecord]

    func findByFingerprint(
        _ fingerprint: String
    ) async throws -> OutOfBandRecord?

    func getAll() async -> [OutOfBandRecord]

    func deleteById(
        _ outOfBandId: String
    ) async throws
    
    func waitForHandshakeReuse() async throws -> Bool
    
    func updateState(outOfBandRecord: inout OutOfBandRecord, newState: OutOfBandState) async throws
}

extension OutOfBandService: OutOfBandServiceProtocol {}
