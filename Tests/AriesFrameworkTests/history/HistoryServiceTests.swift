//
//  HistoryServiceTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 23/02/26.
//

import XCTest
@testable import AriesFramework

final class HistoryServiceTests: XCTestCase {

    private var repo: MockHistoryRepository!
    private var sut: HistoryService!

    override func setUp() {
        super.setUp()
        repo = MockHistoryRepository(agent: Agent(agentConfig: .test(), agentDelegate: nil))
        sut = HistoryService(historyRepository: repo)
    }

    func test_save_whenConnectionIsNil_setsDefaultsAndSaves() async throws {
        // given
        let id = "assoc-1"

        // when
        let saved = try await sut.save(
            historyType: HistoryType.credentialRevoked,
            connection: nil,
            associatedRecordId: id,
        )

        // then
        XCTAssertTrue(repo.saveCalled)
        XCTAssertEqual(repo.lastSaved?.associatedRecordId, id)
        XCTAssertEqual(repo.lastSaved?.connectionId, "")
        XCTAssertNil(repo.lastSaved?.theirLabel)
        XCTAssertEqual(repo.lastSaved?.content, "none content")
        XCTAssertEqual(saved.associatedRecordId, id)
    }

    func test_save_whenConnectionProvided_copiesConnectionFieldsAndContent() async throws {
        
        let connection = ConnectionRecordTestFactory.readyConnection()
        let id = "assoc-2"

        let saved = try await sut.save(
            historyType: .credentialRevoked,
            connection: connection,
            associatedRecordId: id,
            content: "hello"
        )

        // then
        XCTAssertTrue(repo.saveCalled)
        XCTAssertEqual(repo.lastSaved?.connectionId, connection.id)
        XCTAssertEqual(repo.lastSaved?.theirLabel, connection.theirLabel)
        XCTAssertEqual(repo.lastSaved?.content, "hello")
        XCTAssertEqual(saved.connectionId, connection.id)
    }

    func test_save_passesOptionalFields() async throws {
        // given
        let connection = ConnectionRecordTestFactory.readyConnection()
        let id = "assoc-3"

        let preview = [
            CredentialPreviewAttribute(name: "name", mimeType: "mimetype", value: "Carine")
        ]

        let anoncreds: RequestedCredentialsAnoncreds? = nil
        let creds: [CredentialRecordBinding]? = nil

        // when
        _ = try await sut.save(
            historyType: .credentialRevoked,
            connection: connection,
            associatedRecordId: id,
            content: "x",
            proofRequestedCredentialsAnoncreds: anoncreds,
            credentials: creds,
            credentialPreviewAttr: preview,
            proofRequestedCredentials: nil
        )

        // then
        XCTAssertEqual(repo.lastSaved?.credentialPreviewAttr?.first?.name, "name")
        XCTAssertEqual(repo.lastSaved?.credentialPreviewAttr?.first?.value, "Carine")
        XCTAssertEqual(repo.lastSaved?.proofRequestedCredentialsAnoncreds?.requestedAttributes.count, anoncreds?.requestedAttributes.count)
        XCTAssertEqual(repo.lastSaved?.credentials?.count, creds?.count)
    }


}
