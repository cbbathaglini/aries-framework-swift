//
//  RequestedCredentialsForProofRequestProcessorTests.swift
//  aries-framework-swiftTests
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/26.
//

import XCTest
@testable import AriesFramework

final class RequestedCredentialsForProofRequestProcessorTests: XCTestCase {

    private var sut: RequestedCredentialsForProofRequestProcessor!

    private var agent: Agent!
    private var common: CommonFunctions!

    private var anonCredsHolderServiceMock: MockAnonCredsHolderService!
    private var revocationServiceMock: MockRevocationService!

    override func setUp() async throws {
        try await super.setUp()

        agent = Agent(agentConfig: .test(), agentDelegate: nil)

        anonCredsHolderServiceMock = MockAnonCredsHolderService()
        revocationServiceMock = MockRevocationService(agent: agent)

        agent.anonCredsHolderService = anonCredsHolderServiceMock
        agent.revocationService = revocationServiceMock

        common = CommonFunctions(agent: agent, proofFormats: [])
        sut = RequestedCredentialsForProofRequestProcessor(agent: agent, common: common)
    }

    override func tearDown() {
        sut = nil
        revocationServiceMock = nil
        anonCredsHolderServiceMock = nil
        common = nil
        agent = nil
        super.tearDown()
    }

    func testGetRequestedCredentials_WhenOnlyAttributes_ShouldReturnRequestedAttributes() async throws {
        let proofRequest = AnonCredsProofRequestBuilder()
            .setName("proof-1")
            .setRequestedAttributes([
                "attr1_referent": AnonCredsRequestedAttributeBuilder()
                    .setName("name")
                    .build()
            ])
            .setRequestedPredicates([:])
            .build()

        let credential = CredentialForProofRequestBuilder()
            .setCredentialId("cred-1")
            .build()

        anonCredsHolderServiceMock.credentialsForProofRequestToReturn =
            GetCredentialsForProofRequestReturn(credentials: [credential])

        let result = try await sut.getRequestedCredentials(for: proofRequest)

        XCTAssertEqual(result.requestedAttributes["attr1_referent"]?.count, 1)
        XCTAssertEqual(result.requestedAttributes["attr1_referent"]?.first?.credentialId, "cred-1")
        XCTAssertEqual(result.requestedAttributes["attr1_referent"]?.first?.revealed, true)

        XCTAssertTrue(result.requestedPredicates.isEmpty)
        XCTAssertEqual(anonCredsHolderServiceMock.getCredentialsForProofRequestCalls.count, 1)
    }

    func testGetRequestedCredentials_WhenOnlyPredicates_ShouldReturnRequestedPredicates() async throws {
        let predicate = AnonCredsRequestedPredicateBuilder()
            .setName("age")
            .setPType(.GreaterThanOrEqualTo)
            .setPValue(18)
            .build()

        let proofRequest = AnonCredsProofRequestBuilder()
            .setName("proof-2")
            .setRequestedAttributes([:])
            .setRequestedPredicates([
                "pred1_referent": predicate
            ])
            .build()

        let credential = CredentialForProofRequestBuilder()
            .setCredentialId("cred-2")
            .build()

        anonCredsHolderServiceMock.credentialsForProofRequestToReturn =
            GetCredentialsForProofRequestReturn(credentials: [credential])

        let result = try await sut.getRequestedCredentials(for: proofRequest)

        XCTAssertEqual(result.requestedPredicates["pred1_referent"]?.count, 1)
        XCTAssertEqual(result.requestedPredicates["pred1_referent"]?.first?.credentialId, "cred-2")

        XCTAssertTrue(result.requestedAttributes.isEmpty)
        XCTAssertEqual(anonCredsHolderServiceMock.getCredentialsForProofRequestCalls.count, 1)
    }

    func testGetRequestedCredentials_WhenAttributeAndPredicate_ShouldReturnBoth() async throws {
        let proofRequest = AnonCredsProofRequestBuilder()
            .setName("proof-3")
            .setRequestedAttributes([
                "attr1": AnonCredsRequestedAttributeBuilder()
                    .setName("name")
                    .build()
            ])
            .setRequestedPredicates([
                "pred1": AnonCredsRequestedPredicateBuilder()
                    .setName("age")
                    .setPType(.GreaterThanOrEqualTo)
                    .setPValue(18)
                    .build()
            ])
            .build()

        let credential = CredentialForProofRequestBuilder()
            .setCredentialId("cred-3")
            .build()

        anonCredsHolderServiceMock.credentialsForProofRequestToReturn =
            GetCredentialsForProofRequestReturn(credentials: [credential])

        let result = try await sut.getRequestedCredentials(for: proofRequest)

        XCTAssertEqual(result.requestedAttributes["attr1"]?.first?.credentialId, "cred-3")
        XCTAssertEqual(result.requestedPredicates["pred1"]?.first?.credentialId, "cred-3")
        XCTAssertEqual(anonCredsHolderServiceMock.getCredentialsForProofRequestCalls.count, 2)
    }

    func testGetRequestedCredentials_WhenCredentialW3cIdProvided_ShouldForwardChosenCredentialId() async throws {
        let proofRequest = AnonCredsProofRequestBuilder()
            .setName("proof-4")
            .setRequestedAttributes([
                "attr1": AnonCredsRequestedAttributeBuilder()
                    .setName("name")
                    .build()
            ])
            .build()

        let credential = CredentialForProofRequestBuilder()
            .setCredentialId("cred-4")
            .build()

        anonCredsHolderServiceMock.credentialsForProofRequestToReturn =
            GetCredentialsForProofRequestReturn(credentials: [credential])

        _ = try await sut.getRequestedCredentials(for: proofRequest, credentialW3cId: "w3c-123")

        XCTAssertEqual(
            anonCredsHolderServiceMock.getCredentialsForProofRequestCalls.first?.chosenCredentialId,
            "w3c-123"
        )
    }

    func testGetRequestedCredentials_WhenNoRevocationData_ShouldReturnNilRevokedAndTimestamp() async throws {
        let proofRequest = AnonCredsProofRequestBuilder()
            .setName("proof-5")
            .setRequestedAttributes([
                "attr1": AnonCredsRequestedAttributeBuilder()
                    .setName("name")
                    .build()
            ])
            .build()

        let credential = CredentialForProofRequestBuilder()
            .setCredentialId("cred-5")
            .setCredentialRevocationId(nil)
            .setRevocationRegistryId(nil)
            .build()

        anonCredsHolderServiceMock.credentialsForProofRequestToReturn =
            GetCredentialsForProofRequestReturn(credentials: [credential])

        let result = try await sut.getRequestedCredentials(for: proofRequest)

        let attr = result.requestedAttributes["attr1"]?.first
        XCTAssertEqual(attr?.credentialId, "cred-5")
        XCTAssertNil(attr?.revoked)
        XCTAssertNil(attr?.timestamp)

        XCTAssertEqual(revocationServiceMock.getRevocationStatusCallCount, 0)
    }

    func testGetRequestedCredentials_WhenIgnoreRevocationCheckIsTrue_ShouldNotCallRevocationService() async throws {
        agent.agentConfig.ignoreRevocationCheck = true

        let nonRevoked = AnonCredsNonRevokedInterval(from: 10, to: 20)

        let proofRequest = AnonCredsProofRequestBuilder()
            .setName("proof-6")
            .setRequestedAttributes([
                "attr1": AnonCredsRequestedAttributeBuilder()
                    .setName("name")
                    .setNonRevoked(nonRevoked)
                    .build()
            ])
            .build()

        let credential = CredentialForProofRequestBuilder()
            .setCredentialId("cred-6")
            .setCredentialRevocationId("5")
            .setRevocationRegistryId("rev-reg-1")
            .build()

        anonCredsHolderServiceMock.credentialsForProofRequestToReturn =
            GetCredentialsForProofRequestReturn(credentials: [credential])

        let result = try await sut.getRequestedCredentials(for: proofRequest)

        let attr = result.requestedAttributes["attr1"]?.first
        XCTAssertEqual(attr?.revoked, false)
        XCTAssertEqual(attr?.timestamp, 20)

        XCTAssertEqual(revocationServiceMock.getRevocationStatusCallCount, 0)
    }

    func testGetRequestedCredentials_WhenRevocationCheckNeeded_ShouldCallRevocationService() async throws {
        agent.agentConfig.ignoreRevocationCheck = false

        agent.revocationService = revocationServiceMock
        
        let nonRevoked = AnonCredsNonRevokedInterval(from: 100, to: 200)

        let proofRequest = AnonCredsProofRequestBuilder()
            .setName("proof-7")
            .setRequestedAttributes([
                "attr1": AnonCredsRequestedAttributeBuilder()
                    .setName("name")
                    .setNonRevoked(nonRevoked)
                    .build()
            ])
            .build()

        let credential = CredentialForProofRequestBuilder()
            .setCredentialId("cred-7")
            .setCredentialRevocationId("7")
            .setRevocationRegistryId("did:ethr:serpro:0x1838fd02b8e95b7cb5f7aeb2d2f3852bca6e9432/anoncreds/v0/REV_REG_DEF/did:ethr:serpro:0x1838fd02b8e95b7cb5f7aeb2d2f3852bca6e9432:schema_revoked_dcf2b3e5-ff4f-4891-9f2a-ef304a90056d:1.0/default/CL_ACCUM:0")
            .build()

        anonCredsHolderServiceMock.credentialsForProofRequestToReturn =
            GetCredentialsForProofRequestReturn(credentials: [credential])

        revocationServiceMock.revocationStatusToReturn = (true, 150)

        let result = try await sut.getRequestedCredentials(for: proofRequest)

        let attr = result.requestedAttributes["attr1"]?.first
        XCTAssertEqual(attr?.revoked, true)
        XCTAssertEqual(attr?.timestamp, 150)

        XCTAssertEqual(revocationServiceMock.getRevocationStatusCallCount, 1)
        XCTAssertEqual(revocationServiceMock.receivedCredentialRevocationId, "7")
        XCTAssertEqual(revocationServiceMock.receivedRevocationRegistryId, "did:ethr:serpro:0x1838fd02b8e95b7cb5f7aeb2d2f3852bca6e9432/anoncreds/v0/REV_REG_DEF/did:ethr:serpro:0x1838fd02b8e95b7cb5f7aeb2d2f3852bca6e9432:schema_revoked_dcf2b3e5-ff4f-4891-9f2a-ef304a90056d:1.0/default/CL_ACCUM:0")
    }

    func testGetRequestedCredentials_WhenHolderServiceFails_ShouldThrow() async {
        let proofRequest = AnonCredsProofRequestBuilder()
            .setName("proof-8")
            .setRequestedAttributes([
                "attr1": AnonCredsRequestedAttributeBuilder()
                    .setName("name")
                    .build()
            ])
            .build()

        anonCredsHolderServiceMock.errorToThrow = CredoError("holder failed")

        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.getRequestedCredentials(for: proofRequest)
        } assertion: { error in
//            XCTAssertTrue(
//                String(describing: error).contains("holder failed") ||
//                error.localizedDescription.contains("holder failed")
//            )
            XCTAssertTrue(error is CredoError)
        }
    }

    // MARK: - Helper

    func XCTAssertThrowsErrorAsync(
        _ expression: @escaping () async throws -> Void,
        assertion: ((Error) -> Void)? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await expression()
            XCTFail("Expected error to be thrown", file: file, line: line)
        } catch {
            assertion?(error)
        }
    }
}
