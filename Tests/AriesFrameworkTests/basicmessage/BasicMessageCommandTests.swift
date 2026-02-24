//
//  BasicMessageCommandTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

import XCTest
@testable import AriesFramework

final class BasicMessageCommandTests: XCTestCase {

    func testBasicMessageCommand_registersHandler() {
        
        let dispatcher = MockDispatcher()
        let agent = MockAgent()

        
        _ = BasicMessageCommand(
            agent: agent,
            dispatcher: dispatcher
        )

        
        XCTAssertEqual(dispatcher.registeredHandlers.count, 1)
        XCTAssertTrue(dispatcher.registeredHandlers.first is BasicMessageHandler)
    }
}
