////
////  InboundMessageContextTests.swift
////  aries-framework-swift
////
////  Created by Carine Bertagnolli Bathaglini on 19/12/25.
////
//
//import XCTest
//@testable import AriesFramework
//
//final class InboundMessageContextTests: XCTestCase {
//
//    private func makeContext(
//        connection: ConnectionRecord?
//    ) -> InboundMessageContext {
//        return InboundMessageContext(
//            message: DummyAgentMessage(),
//            plaintextMessage: "{}",
//            connection: connection,
//            senderVerkey: "sender",
//            recipientVerkey: "recipient"
//        )
//    }
//
//    func testAssertReadyConnection_returnsConnection_whenReady() throws {
//        let connection = MockConnectionRecord(isReady: true)
//        let context = makeContext(connection: connection)
//
//        let result = try context.assertReadyConnection()
//
//        XCTAssertTrue(result === connection)
//    }
//
//    func testAssertReadyConnection_throws_whenConnectionIsNil() {
//        let context = makeContext(connection: nil)
//
//        XCTAssertThrowsError(try context.assertReadyConnection())
//    }
//
//    func testAssertReadyConnection_throws_whenConnectionIsNotReady() {
//        let connection = MockConnectionRecord(isReady: false)
//        let context = makeContext(connection: connection)
//
//        XCTAssertThrowsError(try context.assertReadyConnection())
//    }
//}
