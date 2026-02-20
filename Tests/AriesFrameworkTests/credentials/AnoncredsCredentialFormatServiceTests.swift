//
//  AnoncredsCredentialFormatServiceTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

import XCTest
@testable import AriesFramework

final class AnoncredsCredentialFormatServiceTests: XCTestCase {
    
    func test_createProposal_success() async throws {
        // Arrange
        let agent = Agent(
            agentConfig: .test(),
            agentDelegate: nil
        )
        
        let service = AnoncredsCredentialFormatService(agent: agent)

        let formats = AnoncredsCredentialFormatTestFactory.validCredentialFormats()
        let record = CredentialExchangeRecordTestFactory.empty()

        // Act
        let result = try await service.createProposal(
            credentialFormats: formats,
            credentialExchangeRecord: record
        )

        // Assert — Format
        XCTAssertEqual(
            result.format.format,
            AnoncredsCredentialFormatService.ANONCREDS_CREDENTIAL_FILTER
        )

        // Assert — Attachment
        XCTAssertEqual(result.attachment.id, result.format.attachId)

        let json = try result.attachment.getDataAsJson()
        XCTAssertTrue(json.contains("schema_id"))
        XCTAssertTrue(json.contains("schema_name"))
        XCTAssertTrue(json.contains("schema_issuer_id"))
        XCTAssertTrue(json.contains("schema_version"))
        XCTAssertTrue(json.contains("cred_def_id"))

        // Assert — Preview attributes
        XCTAssertNotNil(result.previewAttribute)
        XCTAssertFalse(result.previewAttribute!.isEmpty)
    }
    
    func test_createProposal_invalidProposal_throws() async {
        // Arrange
        let agent = Agent(
            agentConfig: .test(),
            agentDelegate: nil
        )
        let service = AnoncredsCredentialFormatService(agent: agent)

        let formats = AnoncredsCredentialFormatTestFactory.invalidCredentialFormats()
        let record = CredentialExchangeRecordTestFactory.empty()

        // Act / Assert
        await XCTAssertThrowsErrorAsync {
            try await service.createProposal(
                credentialFormats: formats,
                credentialExchangeRecord: record
            )
        }
    }
    
    func test_processProposal_success() async throws {
        // Arrange
        let agent = Agent(
            agentConfig: .test(),
            agentDelegate: nil
        )
        let service = AnoncredsCredentialFormatService(agent: agent)

        let proposal = AnonCredsCredentialProposal(
            schemaIssuerDid: "did:example:issuer",
            schemaIssuerId: "issuer-id",
            schemaId: "schema:1",
            schemaName: "TestSchema",
            schemaVersion: "1.0",
            credentialDefinitionId: "creddef:1",
            issuerDid: "did:example:issuer",
            issuerId: "issuer-id"
        )

        let attachment = try FormatDataUtil.getFormatData(
            proposal,
            id: "proposal-attach-id"
        )

        let record = CredentialExchangeRecordBuilder().build()

        // Act / Assert 
        try await service.processProposal(
            attachment: attachment,
            credentialRecord: record
        )
    }
    
    func test_processProposal_invalidAttachment_throws() async {
        // Arrange
        let agent = Agent(
            agentConfig: .test(),
            agentDelegate: nil
        )
        let service = AnoncredsCredentialFormatService(agent: agent)

        let invalidJson = "{ \"foo\": \"bar\" }"
        let attachment = Attachment.fromData(
            invalidJson.data(using: .utf8)!,
            id: "invalid"
        )

        let record = CredentialExchangeRecordBuilder().build()

        // Act / Assert
        await XCTAssertThrowsErrorAsync {
            try await service.processProposal(
                attachment: attachment,
                credentialRecord: record
            )
        }
    }
    
    func test_acceptProposal_success() async throws {
        // Arrange
        let agent = Agent(
            agentConfig: .test(),
            agentDelegate: nil
        )
        agent.wallet = MockWallet()
        agent.credentialExchangeRepository = MockCredentialExchangeRepository(agent: agent)
        agent.didCommMessageRepository = MockDidCommMessageRepository(agent: agent)
        agent.connectionRepository = MockConnectionRepository()
        agent.anonCredsIssuerService = MockAnonCredsIssuerService()
        
        let schema = AnonCredsSchema(
            issuerId: "did:test",
            name: "TestSchema",
            version: "1.0",
            attrNames: ["name"],
        )

        let registry = MockAnonCredsRegistry(schema: schema)

        agent.anonCredsRegistryService =
            MockAnonCredsRegistryService(registry: registry)
    
        let service = AnoncredsCredentialFormatService(agent: agent)

        let attribute = CredentialPreviewAttributeBuilder()
            .withName("name")
            .withValue("Alice")
            .build()

        let anoncredsFormat = AnoncredsCredentialFormatBuilder()
            .withCredentialDefinitionId("creddef:1")
            .withAttribute(attribute)
            .build()

        let encoder = JSONEncoder()
        let data = try encoder.encode(anoncredsFormat)
        let jsonObject = try JSONSerialization.jsonObject(with: data)

        let credentialFormats: [String: Any] = [
            "anoncreds": jsonObject
        ]

        let proposalFormat = AnonCredsCredentialProposalFormatBuilder()
            .withCredentialDefinitionId("creddef:1")
            .build()

        let proposalAttachment = try FormatDataUtil.getFormatData(
            proposalFormat,
            id: "proposal-attach"
        )

        let record = CredentialExchangeRecordBuilder()
            .setCredentialAttributes([
                CredentialPreviewAttribute(name: "name", mimeType: "application/json", value: "Alice")
            ])
            .build()

        // Act
        let result = try await service.acceptProposal(
            attachmentId: "offer-attach",
            credentialFormats: credentialFormats,
            credentialRecord: record,
            proposalAttachments: proposalAttachment
        )

        // Assert
        XCTAssertEqual(
            result.format.format,
            AnoncredsCredentialFormatService.ANONCREDS_CREDENTIAL_OFFER
        )

        XCTAssertFalse(result.previewAttributes.isEmpty)
    }
    
    private func XCTAssertThrowsErrorAsync(
        _ expression: @escaping () async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            try await expression()
            XCTFail("Expected error to be thrown", file: file, line: line)
        } catch {
            // success
        }
    }
    
    
}
