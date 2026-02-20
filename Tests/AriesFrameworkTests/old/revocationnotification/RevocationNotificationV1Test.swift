////
////  RevocationNotificationV1Test.swift
////  aries-framework-swift
////
////  Created by Carine Bertagnolli Bathaglini on 24/03/25.
////
//
//import XCTest
//@testable import AriesFramework
//
//final class RevocationNotificationV1Test: XCTestCase {
//
//    var faberAgent: Agent!
//    var aliceAgent: Agent!
//    var credDefId: String!
//    var faberConnection: ConnectionRecord!
//    var aliceConnection: ConnectionRecord!
//
//    let credentialPreview = CredentialPreview.fromDictionary(["name": "John", "age": "99"])
//
//    override func setUp() async throws {
//        try await super.setUp()
//
//        (faberAgent, aliceAgent, faberConnection, aliceConnection) = try await TestHelper.setupCredentialTests()
//        self.credDefId = try await self.prepareForRevocation()
//        
//    }
//
//    override func tearDown() async throws {
//        try await faberAgent?.reset()
//        try await aliceAgent?.reset()
//        try await super.tearDown()
//    }
//
//
//    func testShouldEmitRevocationNotificationEvent() async throws {
//        class TestDelegate: AgentDelegate {
//            let expectation: XCTestExpectation
//            init(expectation: XCTestExpectation) {
//                self.expectation = expectation
//            }
//            func onRevocationNotificationChanged(credentialExchangeRecord: CredentialExchangeRecord) {
//                expectation.fulfill()
//            }
//        }
//        
//        let calledExpectation = expectation(description: "Credential revoked (1.0)")
//        aliceAgent.agentDelegate = TestDelegate(expectation: calledExpectation)
//
//        let (aliceRecord, faberRecord) = try await issueAndAcceptCredential()
//        try await revokeCredential(aliceRecord)
//
//        var result = XCTWaiter.wait(for: [calledExpectation], timeout: 0.1)
//        if result == XCTWaiter.Result.timedOut {
//            // onRevocationNotificationChanged called.
//        } else {
//            XCTFail("onRevocationNotificationChanged not called")
//        }
//    }
//
//    func testShouldNotEmitRevocationNotificationEventBecauseThreadIdIsInvalid() async throws {
//        class TestDelegate: AgentDelegate {
//            let expectation: XCTestExpectation
//            init(expectation: XCTestExpectation) {
//                self.expectation = expectation
//            }
//            func onRevocationNotificationChanged(credentialExchangeRecord: CredentialExchangeRecord) {
//                expectation.fulfill()
//            }
//        }
//        
//        let notCalledExpectation = expectation(description: "Credential revoked (1.0)")
//        aliceAgent.agentDelegate = TestDelegate(expectation: notCalledExpectation)
//    
//
//        let invalidId = "notIndy::invalidRevRegId::invalidCredRevId"
//        let mapMessage = try await aliceAgent.revocationNotificationService.createRevocationNotification(
//            options: RevocationNotificationMessageV1Options(
//                issueThread: invalidId,
//                comment: "Credential has been revoked"
//            )
//        )
//
//        if let message = mapMessage["message"] {
//            let context = InboundMessageContext(
//                message: message,
//                plaintextMessage: message.comment!,
//                connection: nil,
//                senderVerkey: nil,
//                recipientVerkey: nil
//            )
//
//            do {
//                _ = try await faberAgent.revocationNotificationService.processRevocationNotification(messageContext: context)
//                var result = XCTWaiter.wait(for: [notCalledExpectation], timeout: 0.1)
//                if result == XCTWaiter.Result.timedOut {
//                    // onRevocationNotificationChanged not called.
//                } else {
//                    XCTFail("onRevocationNotificationChanged called")
//                }
//                
//            } catch {
//                XCTAssertNotNil(error)
//            }
//
//    
//        } else {
//            XCTFail("Error: Revocation notification message is nil")
//        }
//    }
//
//    func testShouldEmitRevocationNotificationEvent2() async throws {
//
//        class TestDelegate: AgentDelegate {
//            let expectation: XCTestExpectation
//            init(expectation: XCTestExpectation) {
//                self.expectation = expectation
//            }
//            func onRevocationNotificationChanged(credentialExchangeRecord: CredentialExchangeRecord) {
//                expectation.fulfill()
//            }
//        }
//        
//        let calledExpectation = expectation(description: "Credential revoked (1.0)")
//        aliceAgent.agentDelegate = TestDelegate(expectation: calledExpectation)
//        
//        let metadata = [
//            "revocationRegistryId": "3qiQ...default",
//            "credentialRevocationId": "1"
//        ]
//
//        let credentialId = "indy::\(metadata["revocationRegistryId"]!)::\(metadata["credentialRevocationId"]!)"
//
//        let mapMessage = try await aliceAgent.revocationNotificationService.createRevocationNotification(
//            options: RevocationNotificationMessageV1Options(
//                issueThread: credentialId,
//                comment: "Credential has been revoked"
//            )
//        )
//
//        if let message = mapMessage["message"] {
//            let context = InboundMessageContext(
//                message: message,
//                plaintextMessage: message.comment!,
//                connection: aliceConnection,
//                senderVerkey: nil,
//                recipientVerkey: nil
//            )
//
//            _ = try await aliceAgent.credentialRepository.getAll()
//
//
//            _ = try await faberAgent.revocationNotificationService.processRevocationNotification(messageContext: context)
//            var result = XCTWaiter.wait(for: [calledExpectation], timeout: 0.1)
//            if result != XCTWaiter.Result.timedOut {
//                // onRevocationNotificationChanged called.
//            } else {
//                XCTFail("onRevocationNotificationChanged not called")
//            }
//            
//
//        } else {
//            XCTFail("Error: Revocation notification message is nil")
//        }
//    }
//
//
//    // MARK: - Utility Methods
//
//    func getCredentialRecord(agent: Agent, threadId: String) async throws -> CredentialExchangeRecord {
//        return try await agent.credentialExchangeRepository.getByThreadAndConnectionId(threadId: threadId, connectionId: nil)
//    }
//
//    func revokeCredential(_ credential: CredentialExchangeRecord) async throws {
//        guard let didInfo = faberAgent.wallet.publicDid else {
//            throw NSError(domain: "AgentError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Faber has no public DID"])
//        }
//
//        try await faberAgent.ledgerService.revokeCredential(did: didInfo, credDefId: credDefId, revocationIndex: 1)
//        aliceAgent.agentDelegate?.onRevocationNotificationChanged(credentialExchangeRecord: credential)
//    }
//
//    func prepareForRevocation() async throws -> String {
//        guard let didInfo = faberAgent.wallet.publicDid else {
//            throw NSError(domain: "AgentError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing DID"])
//        }
//
//        let schemaId = try await faberAgent.ledgerService.registerSchema(
//            did: didInfo,
//            schemaTemplate: SchemaTemplate(name: "schema-\(UUID().uuidString)", version: "1.0", attributes: ["name", "age"])
//        )
//
//        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
//
//        let (schema, seqNo) = try await faberAgent.ledgerService.getSchema(schemaId: schemaId)
//
//        let credDefId = try await faberAgent.ledgerService.registerCredentialDefinition(
//            did: didInfo,
//            credentialDefinitionTemplate: CredentialDefinitionTemplate(schema: schema, tag: "default", supportRevocation: true, seqNo: seqNo)
//        )
//
//        try await faberAgent.ledgerService.registerRevocationRegistryDefinition(
//            did: didInfo,
//            revRegDefTemplate: RevocationRegistryDefinitionTemplate(credDefId: credDefId, tag: "default", maxCredNum: 100)
//        )
//
//        return credDefId
//    }
//
//    func issueAndAcceptCredential() async throws -> (CredentialExchangeRecord, CredentialExchangeRecord) {
//        var faberCredential = try await faberAgent.credentials.offerCredential(
//            options: CreateOfferOptions(
//                connection: faberConnection,
//                credentialDefinitionId: credDefId,
//                attributes: credentialPreview.attributes,
//                comment: "Offer to Alice"
//            )
//        )
//
//        let threadId = faberCredential.threadId
//        var aliceCredential = try await getCredentialRecord(agent: aliceAgent, threadId: threadId)
//        XCTAssertEqual(aliceCredential.state, .OfferReceived)
//
//        try await aliceAgent.credentials.acceptOffer(options: AcceptOfferOptions(credentialRecordId: aliceCredential.id))
//        faberCredential = try await getCredentialRecord(agent: faberAgent, threadId: threadId)
//        XCTAssertEqual(faberCredential.state, .RequestReceived)
//
//        try await faberAgent.credentials.acceptRequest(options: AcceptRequestOptions(credentialRecordId: faberCredential.id))
//        aliceCredential = try await getCredentialRecord(agent: aliceAgent, threadId: threadId)
//        XCTAssertEqual(aliceCredential.state, .CredentialReceived)
//
//        try await aliceAgent.credentials.acceptCredential(options: AcceptCredentialOptions(credentialRecordId: aliceCredential.id))
//        aliceCredential = try await getCredentialRecord(agent: aliceAgent, threadId: threadId)
//        faberCredential = try await getCredentialRecord(agent: faberAgent, threadId: threadId)
//
//        XCTAssertEqual(aliceCredential.state, .Done)
//        XCTAssertEqual(faberCredential.state, .Done)
//
//        return (aliceCredential, faberCredential)
//    }
//}
