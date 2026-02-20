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
        
        let mockCredDefRepo =
            MockAnonCredsCredentialDefinitionRepository()

        let def = AnonCredsCredentialDefinitionTestFactory.minimal(
            issuerId: "did:test",
            schemaId: "schema:1",
            tag: "default"
        )

        mockCredDefRepo.recordToReturn =
            AnonCredsCredentialDefinitionRecordBuilder()
                .withCredentialDefinitionId("creddef:1")
                .withCredentialDefinition(def)
                .withMethodName("mock")
                .build()

        agent.anonCredsCredentialDefinitionRepository = mockCredDefRepo
    
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
    
    func test_acceptProposal_missingCredDefId_throws() async {
        let agent = makeAgentForAnoncredsTests()
        let service = AnoncredsCredentialFormatService(agent: agent)

        let attribute = CredentialPreviewAttributeBuilder()
            .withName("name")
            .withValue("Alice")
            .build()

        let anoncredsFormat = AnoncredsCredentialFormatBuilder()
            .withCredentialDefinitionId("creddef:1")
            .withAttribute(attribute)
            .build()

        var anoncredsJson = try! jsonObject(anoncredsFormat)
        anoncredsJson = removingKeys(anoncredsJson, [
            "credentialDefinitionId",
            "credential_definition_id",
            "credDefId",
            "cred_def_id"
        ])

        let credentialFormats: [String: Any] = ["anoncreds": anoncredsJson]

        let proposalFormat = AnonCredsCredentialProposalFormatBuilder()
            .withCredentialDefinitionId("creddef:1")
            .build()

        var proposalJson = try! jsonObject(proposalFormat)
        proposalJson = removingKeys(proposalJson, [
            "credentialDefinitionId",
            "credential_definition_id",
            "credDefId",
            "cred_def_id"
        ])

        let proposalAttachment = Attachment.fromData(
            try! JSONSerialization.data(withJSONObject: proposalJson, options: []),
            id: "proposal-attach"
        )

        let record = CredentialExchangeRecordBuilder()
            .setCredentialAttributes([
                CredentialPreviewAttribute(name: "name", mimeType: "application/json", value: "Alice")
            ])
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await service.acceptProposal(
                attachmentId: "offer-attach",
                credentialFormats: credentialFormats,
                credentialRecord: record,
                proposalAttachments: proposalAttachment
            )
        }
    }
    
    func test_acceptProposal_missingAttributes_throws() async {
        let agent = makeAgentForAnoncredsTests()
        let service = AnoncredsCredentialFormatService(agent: agent)

        let anoncredsFormat = AnoncredsCredentialFormatBuilder()
            .withCredentialDefinitionId("creddef:1")
            .withAttribute(
                CredentialPreviewAttributeBuilder().withName("name").withValue("Alice").build()
            )
            .build()

        var anoncredsJson = try! jsonObject(anoncredsFormat)
        ["attributes", "credentialAttributes", "credential_attributes"].forEach {
            anoncredsJson.removeValue(forKey: $0)
        }

        let credentialFormats: [String: Any] = ["anoncreds": anoncredsJson]

        let proposalFormat = AnonCredsCredentialProposalFormatBuilder()
            .withCredentialDefinitionId("creddef:1")
            .build()
        let proposalAttachment = try! FormatDataUtil.getFormatData(proposalFormat, id: "proposal-attach")

        let record = CredentialExchangeRecordBuilder()
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await service.acceptProposal(
                attachmentId: "offer-attach",
                credentialFormats: credentialFormats,
                credentialRecord: record,
                proposalAttachments: proposalAttachment
            )
        }
    }
    
    func test_acceptProposal_credDefRepoFails_throws() async {
        let agent = makeAgentForAnoncredsTests()

        let failingRepo = MockAnonCredsCredentialDefinitionRepository()
        failingRepo.errorToThrow = CredoError("boom")
        agent.anonCredsCredentialDefinitionRepository = failingRepo

        let service = AnoncredsCredentialFormatService(agent: agent)

        let attribute = CredentialPreviewAttributeBuilder().withName("name").withValue("Alice").build()
        let anoncredsFormat = AnoncredsCredentialFormatBuilder().withCredentialDefinitionId("creddef:1").withAttribute(attribute).build()

        let data = try! JSONEncoder().encode(anoncredsFormat)
        let jsonObject = try! JSONSerialization.jsonObject(with: data)
        let credentialFormats: [String: Any] = ["anoncreds": jsonObject]

        let proposalFormat = AnonCredsCredentialProposalFormatBuilder().withCredentialDefinitionId("creddef:1").build()
        let proposalAttachment = try! FormatDataUtil.getFormatData(proposalFormat, id: "proposal-attach")

        let record = CredentialExchangeRecordBuilder()
            .setCredentialAttributes([CredentialPreviewAttribute(name: "name", mimeType: "application/json", value: "Alice")])
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await service.acceptProposal(
                attachmentId: "offer-attach",
                credentialFormats: credentialFormats,
                credentialRecord: record,
                proposalAttachments: proposalAttachment
            )
        }
    }
    
    func test_processOffer_invalidOffer_throwsProblemReport() async {
        let agent = Agent(agentConfig: .test(), agentDelegate: nil)
        let service = AnoncredsCredentialFormatService(agent: agent)

        let invalidOfferJson = """
        {
          "schema_id": "",
          "cred_def_id": "creddef:1",
          "nonce": "123"
        }
        """
        
        let attachment = Attachment.fromData(invalidOfferJson.data(using: .utf8)!, id: "offer")

        let record = CredentialExchangeRecordBuilder().build()

        await XCTAssertThrowsErrorAsync {
            try await service.processOffer(
                attachment: attachment,
                credentialExchangeRecord: record
            )
        }
    }
    
    func test_createOffer_success() async throws {
        let agent = makeAgentForAnoncredsTests() // seu helper que já injeta issuer, registry, credDef repo etc
        let service = AnoncredsCredentialFormatService(agent: agent)

        let attribute = CredentialPreviewAttributeBuilder()
            .withName("name")
            .withValue("Alice")
            .build()

        let anoncredsFormat = AnoncredsCredentialFormatBuilder()
            .withCredentialDefinitionId("creddef:1")
            .withAttribute(attribute)
            .build()

        let anoncredsJson = try jsonObject(anoncredsFormat)
        let credentialFormats: [String: Any] = ["anoncreds": anoncredsJson]

        let record = CredentialExchangeRecordBuilder()
            .setCredentialAttributes([
                CredentialPreviewAttribute(name: "name", mimeType: "application/json", value: "Alice")
            ])
            .build()

        let result = try await service.createOffer(
            credentialFormats: credentialFormats,
            credentialExchangeRecord: record,
            attachmentId: "offer-attach"
        )

        XCTAssertEqual(result.format.format, AnoncredsCredentialFormatService.ANONCREDS_CREDENTIAL_OFFER)
        XCTAssertEqual(result.attachment.id, result.format.attachId)
        XCTAssertFalse(result.previewAttributes.isEmpty)
    }
    
    func test_createOffer_missingAttributes_throws() async {
        let agent = makeAgentForAnoncredsTests()
        let service = AnoncredsCredentialFormatService(agent: agent)

        let attribute = CredentialPreviewAttributeBuilder()
            .withName("name")
            .withValue("Alice")
            .build()

        let anoncredsFormat = AnoncredsCredentialFormatBuilder()
            .withCredentialDefinitionId("creddef:1")
            .withAttribute(attribute)
            .build()

        var anoncredsJson = try! jsonObject(anoncredsFormat)
        // remove attributes
        anoncredsJson.removeValue(forKey: "attributes")

        let credentialFormats: [String: Any] = ["anoncreds": anoncredsJson]

        let record = CredentialExchangeRecordBuilder()
            .setCredentialAttributes([
                CredentialPreviewAttribute(name: "name", mimeType: "application/json", value: "Alice")
            ])
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await service.createOffer(
                credentialFormats: credentialFormats,
                credentialExchangeRecord: record,
                attachmentId: "offer-attach"
            )
        }
    }
    
    func test_createOffer_previewDoesNotMatchSchema_throws() async {
        let agent = makeAgentForAnoncredsTests() // schema mock: ["name"]
        let service = AnoncredsCredentialFormatService(agent: agent)

        let attribute = CredentialPreviewAttributeBuilder()
            .withName("age")
            .withValue("30")
            .build()

        let anoncredsFormat = AnoncredsCredentialFormatBuilder()
            .withCredentialDefinitionId("creddef:1")
            .withAttribute(attribute)
            .build()

        let anoncredsJson = try! jsonObject(anoncredsFormat)
        let credentialFormats: [String: Any] = ["anoncreds": anoncredsJson]

        let record = CredentialExchangeRecordBuilder()
            .setCredentialAttributes([
                CredentialPreviewAttribute(name: "age", mimeType: "application/json", value: "30")
            ])
            .build()

        await XCTAssertThrowsErrorAsync {
            _ = try await service.createOffer(
                credentialFormats: credentialFormats,
                credentialExchangeRecord: record,
                attachmentId: "offer-attach"
            )
        }
    }
    
    func test_processOffer_valid_doesNotThrow() async throws {
        let agent = Agent(agentConfig: .test(), agentDelegate: nil)
        let service = AnoncredsCredentialFormatService(agent: agent)

        let offerJson = """
        {
          "schema_id": "schema:1",
          "cred_def_id": "creddef:1",
          "nonce": "123"
        }
        """
        let attachment = Attachment.fromData(offerJson.data(using: .utf8)!, id: "offer")

        let record = CredentialExchangeRecordBuilder().build()

        try await service.processOffer(
            attachment: attachment,
            credentialExchangeRecord: record
        )
    }

    
    func test_shouldAutoRespondToProposal_true() async throws {
        let agent = Agent(agentConfig: .test(), agentDelegate: nil)
        let service = AnoncredsCredentialFormatService(agent: agent)

        let offer = AnonCredsCredentialOfferBuilder()
            .withSchemaId("schema:1")
            .withCredentialDefinitionId("creddef:1")
            .withNonce("123")
            .build()

        let proposal = AnonCredsCredentialProposalFormatBuilder()
            .withCredentialDefinitionId("creddef:1")
            .build()

        let offerAttachment = try FormatDataUtil.getFormatData(offer, id: "offer")
        let proposalAttachment = try FormatDataUtil.getFormatData(proposal, id: "proposal")

        let record = CredentialExchangeRecordBuilder().build()

        let ok = try await service.shouldAutoRespondToProposal(
            credentialRecord: record,
            offerAttachment: offerAttachment,
            proposalAttachment: proposalAttachment
        )

        XCTAssertTrue(ok)
    }

    func test_shouldAutoRespondToProposal_false() async throws {
        let agent = Agent(agentConfig: .test(), agentDelegate: nil)
        let service = AnoncredsCredentialFormatService(agent: agent)

        let offer = AnonCredsCredentialOfferBuilder()
            .withSchemaId("schema:1")
            .withCredentialDefinitionId("creddef:1")
            .withNonce("123")
            .build()

        let proposal = AnonCredsCredentialProposalFormatBuilder()
            .withCredentialDefinitionId("creddef:DIFFERENT")
            .build()

        let offerAttachment = try FormatDataUtil.getFormatData(offer, id: "offer")
        let proposalAttachment = try FormatDataUtil.getFormatData(proposal, id: "proposal")

        let record = CredentialExchangeRecordBuilder().build()

        let ok = try await service.shouldAutoRespondToProposal(
            credentialRecord: record,
            offerAttachment: offerAttachment,
            proposalAttachment: proposalAttachment
        )

        XCTAssertFalse(ok)
    }
    
    func test_shouldAutoRespondToRequest_true() async throws {
        let agent = Agent(agentConfig: .test(), agentDelegate: nil)
        let service = AnoncredsCredentialFormatService(agent: agent)

        let offer = AnonCredsCredentialOfferBuilder()
            .withSchemaId("schema:1")
            .withCredentialDefinitionId("creddef:1")
            .withNonce("123")
            .build()

        let request = AnonCredsCredentialRequestBuilder()
            .withCredentialDefinitionId("creddef:1")
            .build()

        let offerAttachment = try FormatDataUtil.getFormatData(offer, id: "offer")
        let requestAttachment = try FormatDataUtil.getFormatData(request, id: "request")
        let proposalAttachment = Attachment.fromData(Data(), id: "proposal-unused") // não é usado no método

        let record = CredentialExchangeRecordBuilder().build()

        let ok = try await service.shouldAutoRespondToRequest(
            credentialRecord: record,
            offerAttachment: offerAttachment,
            requestAttachment: requestAttachment,
            proposalAttachment: proposalAttachment
        )

        XCTAssertTrue(ok)
    }
    
    func test_supportsFormat_knownFormats_returnTrue() {
        let agent = Agent(agentConfig: .test(), agentDelegate: nil)
        let service = AnoncredsCredentialFormatService(agent: agent)

        XCTAssertTrue(service.supportsFormat("anoncreds/credential-offer@v1.0"))
        XCTAssertTrue(service.supportsFormat("anoncreds/credential-request@v1.0"))
        XCTAssertTrue(service.supportsFormat("anoncreds/credential-filter@v1.0"))
        XCTAssertTrue(service.supportsFormat("anoncreds/credential@v1.0"))
    }
    
    func test_deleteCredentialById_callsHolderService() async throws {
        let agent = Agent(agentConfig: .test(), agentDelegate: nil)
        let holder = MockAnonCredsHolderService()
        agent.anonCredsHolderService = holder

        let service = AnoncredsCredentialFormatService(agent: agent)

        try await service.deleteCredentialById(credentialId: "cred-123")

        XCTAssertEqual(holder.deleteCredentialCalls, ["cred-123"])
    }

    func test_supportsFormat_unknownFormat_returnFalse() {
        let agent = Agent(agentConfig: .test(), agentDelegate: nil)
        let service = AnoncredsCredentialFormatService(agent: agent)

        XCTAssertFalse(service.supportsFormat("w3c/presentation@v2.0"))
    }
    
    //auxiliar functions
    func removingKeys(_ dict: [String: Any], _ keys: [String]) -> [String: Any] {
        var copy = dict
        keys.forEach { copy.removeValue(forKey: $0) }
        return copy
    }
    
    func jsonObject<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        let obj = try JSONSerialization.jsonObject(with: data, options: [])
        return obj as? [String: Any] ?? [:]
    }
    
    private func makeAgentForAnoncredsTests() -> Agent {
        let agent = Agent(agentConfig: .test(), agentDelegate: nil)
        agent.wallet = MockWallet()
        agent.credentialExchangeRepository = MockCredentialExchangeRepository(agent: agent)
        agent.didCommMessageRepository = MockDidCommMessageRepository(agent: agent)
        agent.connectionRepository = MockConnectionRepository()
        agent.anonCredsIssuerService = MockAnonCredsIssuerService()
        
        let schema = AnonCredsSchema(
            issuerId: "did:test",
            name: "TestSchema",
            version: "1.0",
            attrNames: ["name"]
        )
        let registry = MockAnonCredsRegistry(schema: schema)
        agent.anonCredsRegistryService = MockAnonCredsRegistryService(registry: registry)

        let mockCredDefRepo = MockAnonCredsCredentialDefinitionRepository()
        let def = AnonCredsCredentialDefinitionTestFactory.minimal(
            issuerId: "did:test",
            schemaId: "schema:1",
            tag: "default"
        )
        mockCredDefRepo.recordToReturn =
            AnonCredsCredentialDefinitionRecordBuilder()
                .withCredentialDefinitionId("creddef:1")
                .withCredentialDefinition(def)
                .withMethodName("mock")
                .build()
        agent.anonCredsCredentialDefinitionRepository = mockCredDefRepo

        return agent
    }
    
}
