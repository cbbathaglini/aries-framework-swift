//
//  MockDispatcher.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

@testable import AriesFramework

final class MockDispatcher: DispatcherProtocol {

    private(set) var registeredHandlers: [MessageHandler] = []

    func registerHandler(handler: MessageHandler) {
        registeredHandlers.append(handler)
    }
}
