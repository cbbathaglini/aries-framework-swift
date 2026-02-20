//
//  ConnectionRecordBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//
@testable import AriesFramework
import Foundation

final class ConnectionRecordBuilder {

    private var id: String = UUID().uuidString
    private var state: ConnectionState = .Invited
    private var role: ConnectionRole = .Invitee
    private var didDoc: DidDoc = DidDocTestFactory.minimal()
    private var did: String = "did:test:123"
    private var verkey: String = "verkey"
    private var theirDidDoc: DidDoc?
    private var theirDid: String?
    private var theirLabel: String?
    private var invitation: ConnectionInvitationMessage?
    private var outOfBandInvitation: OutOfBandInvitation?
    private var alias: String?
    private var autoAcceptConnection: Bool?
    private var imageUrl: String?
    private var multiUseInvitation: Bool = false
    private var threadId: String?
    private var mediatorId: String?

    // MARK: - Fluent setters
    
    func withId(_ id: String) -> Self {
        self.id = id
        return self
    }

    func withState(_ state: ConnectionState) -> Self {
        self.state = state
        return self
    }
    
    
    func withTheirLabel(_ theirLabel: String?) -> Self {
        self.theirLabel = theirLabel
        return self
    }

    func withRole(_ role: ConnectionRole) -> Self {
        self.role = role
        return self
    }

    func withDid(_ did: String) -> Self {
        self.did = did
        return self
    }

    func withVerkey(_ verkey: String) -> Self {
        self.verkey = verkey
        return self
    }

    func withThreadId(_ threadId: String) -> Self {
        self.threadId = threadId
        return self
    }

    func withOutOfBandInvitation(_ invitation: OutOfBandInvitation) -> Self {
        self.outOfBandInvitation = invitation
        return self
    }

    func withTheirDidDoc(_ didDoc: DidDoc) -> Self {
        self.theirDidDoc = didDoc
        return self
    }

    func withMediatorId(_ mediatorId: String) -> Self {
        self.mediatorId = mediatorId
        return self
    }

    func autoAccept(_ value: Bool) -> Self {
        self.autoAcceptConnection = value
        return self
    }

    func build() -> ConnectionRecord {
        
        var record = ConnectionRecord(
            state: state,
            role: role,
            didDoc: didDoc,
            did: did,
            verkey: verkey,
            theirDidDoc: theirDidDoc,
            theirDid: theirDid,
            theirLabel: theirLabel,
            invitation: invitation,
            alias: alias,
            autoAcceptConnection: autoAcceptConnection,
            imageUrl: imageUrl,
            multiUseInvitation: multiUseInvitation,
            threadId: threadId,
            mediatorId: mediatorId
        )
        
        record.id = id
        record.outOfBandInvitation = outOfBandInvitation
        return record
    }
}
