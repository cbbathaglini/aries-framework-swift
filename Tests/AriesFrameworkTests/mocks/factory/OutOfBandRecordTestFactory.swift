//
//  OutOfBandRecordTestFactory.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

@testable import AriesFramework
import Foundation

@testable import AriesFramework
import Foundation

enum OutOfBandRecordTestFactory {

    static func make(
        id: String = UUID().uuidString,
        role: OutOfBandRole = .Receiver,
        state: OutOfBandState = .Initial,
        reusable: Bool = false,
        autoAcceptConnection: Bool? = nil,
        mediatorId: String? = nil,
        reuseConnectionId: String? = nil,
        invitation: OutOfBandInvitation = OutOfBandInvitationTestFactory.make()
    ) -> OutOfBandRecord {
        OutOfBandRecord(
            id: id,
            createdAt: Date(),
            updatedAt: nil,
            tags: nil,
            metadata: [:],
            outOfBandInvitation: invitation,
            role: role,
            state: state,
            reusable: reusable,
            autoAcceptConnection: autoAcceptConnection,
            mediatorId: mediatorId,
            reuseConnectionId: reuseConnectionId
        )
    }

    static func ready(
        invitation: OutOfBandInvitation = OutOfBandInvitationTestFactory.make()
    ) -> OutOfBandRecord {
        make(
            role: .Receiver,
            state: .Done,
            reusable: false,
            invitation: invitation
        )
    }

    static func reusable(
        invitation: OutOfBandInvitation = OutOfBandInvitationTestFactory.make()
    ) -> OutOfBandRecord {
        make(
            role: .Sender,
            state: .Done,
            reusable: true,
            invitation: invitation
        )
    }
}
