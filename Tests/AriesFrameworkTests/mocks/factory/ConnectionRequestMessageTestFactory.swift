//
//  ConnectionRequestMessageTestFactory.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

import Foundation
@testable import AriesFramework

enum ConnectionRequestMessageTestFactory {

    static func minimal(
        id: String = UUID().uuidString,
        label: String = "test",
        imageUrl: String? = nil
    ) -> ConnectionRequestMessage {
        ConnectionRequestMessage(
            id: id,
            label: label,
            imageUrl: imageUrl,
            connection: ConnectionTestFactory.minimal()
        )
    }
}
