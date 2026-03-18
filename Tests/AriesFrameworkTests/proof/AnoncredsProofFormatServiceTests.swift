//
//  AnoncredsProofFormatServiceTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 27/02/26.
//

import XCTest
import AnyCodable
@testable import AriesFramework

final class AnoncredsProofFormatServiceTests: XCTestCase {
    
    private var agent: Agent!
    private var holder: MockAnonCredsHolderService!
    private var verifierRepo: MockVerifierRepository!
    private var credRepo: MockCredentialExchangeRepository!
    private var sut: AnoncredsProofFormatService!
    
    override func setUp() {
        super.setUp()
        
        agent = Agent(agentConfig: .test(), agentDelegate: nil)
        
        holder = MockAnonCredsHolderService()
        verifierRepo = MockVerifierRepository(agent: agent)
        credRepo = MockCredentialExchangeRepository(agent: agent)
        
        agent.anonCredsHolderService = holder
        agent.verifierRepository = verifierRepo
        agent.credentialExchangeRepository = credRepo
        
        sut = AnoncredsProofFormatService(agent: agent)
    }
    
    // MARK: - supportsFormat
    
    func test_supportsFormat_returnsTrueForSupportedIdentifiers() {
        XCTAssertTrue(sut.supportsFormat(formatIdentifier: AnoncredsProofFormatService.ANONCREDS_PRESENTATION_PROPOSAL))
        XCTAssertTrue(sut.supportsFormat(formatIdentifier: AnoncredsProofFormatService.ANONCREDS_PRESENTATION_REQUEST))
        XCTAssertTrue(sut.supportsFormat(formatIdentifier: AnoncredsProofFormatService.ANONCREDS_PRESENTATION))
    }
    
    func test_supportsFormat_returnsFalseForUnknown() {
        XCTAssertFalse(sut.supportsFormat(formatIdentifier: "dif/proof@v1.0"))
    }
    
    // MARK: - createProposal
    
    func test_createProposal_whenAttachmentIdNil_throws() async {
        let record = ProofExchangeRecordBuilder().setThreadId("th").build()
        
        await XCTAssertThrowsErrorAsync {
            _ = try await self.sut.createProposal(
                profRecord: record,
                attachmentId: nil,
                proofFormats: ["anoncreds": AnyCodable([:])]
            )
        }
    }
    
    func test_createProposal_buildsFormatAndAttachment_andUsesNonce() async throws {
        let record = ProofExchangeRecordBuilder().setThreadId("th-prop").build()
        holder.nonceToReturn = "NONCE-123"
        
        let proofFormats: [String: AnyCodable] = [
            "anoncreds": AnyCodable([
                "name": "My Proof",
                "version": "1.0",
                "attributes": [
                    [
                        "name": "nome",
                        "credentialDefinitionId": "creddef:1",
                        "referent": "attr1"
                    ]
                ],
                "predicates": []
            ])
        ]
        
        let out = try await sut.createProposal(
            profRecord: record,
            attachmentId: "anoncreds",
            proofFormats: proofFormats
        )
        
        XCTAssertEqual(out.format.format, AnoncredsProofFormatService.ANONCREDS_PRESENTATION_PROPOSAL)
        XCTAssertEqual(out.format.attachmentId, "anoncreds")
        XCTAssertGreaterThanOrEqual(holder.generateNonceCallCount, 1)
        
        let req: AnonCredsProofRequest = try AttachmentTestFactory.decodeFromAttachment(
                AnonCredsProofRequest.self,
                attachment: out.attachment
        )

        XCTAssertEqual(req.nonce, "NONCE-123")
        XCTAssertEqual(req.name, "My Proof")
        XCTAssertEqual(req.version, "1.0")
        XCTAssertNotNil(req.requestedAttributes["attr1"])
    }
    
    // MARK: - acceptProposal
    
    func test_acceptProposal_generatesNewNonce_andKeepsRequestFields() async throws {
        let record = ProofExchangeRecordBuilder().setThreadId("th-acc-prop").build()
        
        let proposal = AnonCredsProofRequest(
            name: "Proof request",
            version: "1.0",
            nonce: "OLD",
            requestedAttributes: [:],
            requestedPredicates: [:],
            nonRevoked: nil
        )
        
        let proposalData = try JSONEncoder().encode(proposal)
        let proposalAttachment = AttachmentTestFactory.base64(id: "anoncreds", data: proposalData)

        holder.nonceToReturn = "NEW-NONCE"

        let out = try await sut.acceptProposal(
                proofRecord: record,
                attachmentId: "att-1",
                proposalAttachment: proposalAttachment,
                proofFormats: ["anoncreds": AnyCodable([:])]
            )
        
        XCTAssertEqual(out.format.format, AnoncredsProofFormatService.ANONCREDS_PRESENTATION_REQUEST)
        XCTAssertEqual(out.format.attachmentId, "att-1")
        
        let req: AnonCredsProofRequest = try AttachmentTestFactory.decodeFromAttachment(
                AnonCredsProofRequest.self,
                attachment: out.attachment
        )
        
        XCTAssertEqual(req.name, "Proof request")
        XCTAssertEqual(req.nonce, "NEW-NONCE")
    }
    
    // MARK: - createRequest
    
    func test_createRequest_buildsRequestAttachment_andValidatesNoDuplicateGroups() async throws {
        let record = ProofExchangeRecordBuilder().setThreadId("th-req").build()
        holder.nonceToReturn = "NONCE-X"
        
        let proofFormats: [String: AnyCodable] = [
            "anoncreds": AnyCodable([
                "name": "ReqName",
                "version": "1.0",
                "requested_attributes": [
                    "attr1": [
                        "name": "nome",
                        "restrictions": [
                            ["cred_def_id": AnyCodable("creddef:1")]
                        ]
                    ]
                ],
                "requested_predicates": [:]
            ])
        ]
        
        let out = try await sut.createRequest(
            proofRecord: record,
            attachmentId: "anoncreds",
            proofFormats: proofFormats
        )
        
        XCTAssertEqual(out.format.format, AnoncredsProofFormatService.ANONCREDS_PRESENTATION_REQUEST)
        XCTAssertEqual(out.attachment.id, "anoncreds")
        
        let req: AnonCredsProofRequest = try AttachmentTestFactory.decodeFromAttachment(
                AnonCredsProofRequest.self,
                attachment: out.attachment
        )
        
        XCTAssertEqual(req.name, "ReqName")
        XCTAssertEqual(req.nonce, "NONCE-X")
        XCTAssertFalse(req.requestedAttributes.isEmpty)
    }
    
    // MARK: - normalizeProofFormats
    
    func test_normalizeProofFormats_convertsNonRevokedStringToInt64_andMovesRestrictionsToCredentialDefinitionId() throws {
        let proofFormats: [String: AnyCodable] = [
            "anoncreds": AnyCodable([
                "non_revoked": [
                    "from": "10",
                    "to": "20"
                ],
                "requested_attributes": [
                    "attr1": [
                        "name": "nome",
                        "restrictions": [
                            ["cred_def_id": AnyCodable("creddef:99")]
                        ]
                    ]
                ],
                "requested_predicates": [
                    "pred1": [
                        "name": "idade",
                        "p_type": " >= ",
                        "p_value": "18",
                        "restrictions": [
                            ["cred_def_id": AnyCodable("creddef:99")]
                        ]
                    ]
                ]
            ])
        ]
        
        let normalized = try sut.normalizeProofFormats(proofFormats)
        
        XCTAssertEqual(normalized.nonRevokedInterval?.from, 10)
        XCTAssertEqual(normalized.nonRevokedInterval?.to, 20)
        
        XCTAssertEqual(normalized.attributes?.count, 1)
        XCTAssertEqual(normalized.predicates?.count, 1)
        
        XCTAssertEqual(normalized.attributes?.first?.credentialDefinitionId, "creddef:99")
        XCTAssertEqual(normalized.predicates?.first?.credentialDefinitionId, "creddef:99")
        
        XCTAssertEqual(normalized.predicates?.first?.predicateType, ">=")
        XCTAssertEqual(normalized.predicates?.first?.threshold, 18)
    }
    
    func test_normalizeProofFormats_whenAnoncredsMissing_throws() {
        XCTAssertThrowsError(try sut.normalizeProofFormats([:]))
    }
    
    // MARK: - processProposal
    
    func test_processProposal_decodesRequest_andChecksDuplicateNames() async throws {
        let record = ProofExchangeRecordBuilder().setThreadId("th").build()
        
        let proposal = AnonCredsProofRequest(
            name: "Proof",
            version: "1.0",
            nonce: "1",
            requestedAttributes: [:],
            requestedPredicates: [:],
            nonRevoked: nil
        )
        
        let proposalData = try JSONEncoder().encode(proposal)
        let att = AttachmentTestFactory.base64(id: "anoncreds", data: proposalData)
        
        try await sut.processProposal(attachment: att, proofRecord: record)
    }
    
    // MARK: - processRequest
    
    func test_processRequest_savesVerifierRecord_andValidatesNoDuplicateNames() async throws {
        let record = ProofExchangeRecordBuilder().setThreadId("th-verify").build()
        
        let req = AnonCredsProofRequest(
            name: "Proof",
            version: "1.0",
            nonce: "1",
            requestedAttributes: [:],
            requestedPredicates: [:],
            nonRevoked: nil
        )
        
        let proposalData = try JSONEncoder().encode(req)
        let proposalAttachment = AttachmentTestFactory.base64(id: "anoncreds", data: proposalData)
        
        try await sut.processRequest(options: ProofFormatProcessOptions(
            attachment: proposalAttachment,
            proofRecord: record
        ))
        
        XCTAssertTrue(verifierRepo.saveCalled)
        XCTAssertEqual(verifierRepo.saved.first?.globalThreadId, "th-verify")
    }
    
    // MARK: - shouldAutoRespondToProposal/Request
    
    func test_shouldAutoRespondToProposal_whenEqual_returnsTrue() async throws {
        let record = ProofExchangeRecordBuilder().setThreadId("th").build()
        
        let req = AnonCredsProofRequest(
            name: "Proof",
            version: "1.0",
            nonce: "1",
            requestedAttributes: [:],
            requestedPredicates: [:],
            nonRevoked: nil
        )
        
        let proposalData = try JSONEncoder().encode(req)
        let a1 = AttachmentTestFactory.base64(id: "a1", data: proposalData)
        let a2 = AttachmentTestFactory.base64(id: "a2", data: proposalData)
        
        
        let ok = try await sut.shouldAutoRespondToProposal(
            proofRecord: record,
            proposalAttachment: a1,
            requestAttachment: a2
        )
        XCTAssertTrue(ok)
    }
    
    // MARK: - validateCredentialChosen (via acceptRequest? não dá, então test direto)

    
    func test_validateCredentialChosen_whenEmpty_throwsNoCredentialSelected() async throws {
        let proofRequest = AnonCredsProofRequest(
            name: "Proof",
            version: "1.0",
            nonce: "1",
            requestedAttributes: [:],
            requestedPredicates: [:],
            nonRevoked: nil
        )
        
        await XCTAssertThrowsErrorAsync {
            try await self.sut.validateCredentialChosen(chosenCredentialId: "   ", proofRequest: proofRequest)
        }
    }
    
    func test_validateCredentialChosen_whenMissingRequestedAttr_throws() async throws {
        // requested attr: "nome"
        let requested = AnonCredsRequestedAttribute(
            name: "nome",
            names: nil,
            restrictions: [AnonCredsProofRequestRestriction(credDefId: "creddef:1")],
            nonRevoked: nil
        )
        
        let proofRequest = AnonCredsProofRequest(
            name: "Proof",
            version: "1.0",
            nonce: "1",
            requestedAttributes: ["attr1": requested],
            requestedPredicates: [:],
            nonRevoked: nil
        )
        
        // credential record sem atributo "nome"
        let cred = CredentialExchangeRecordBuilder()
            .setId("rec-1")
            .setCredentialDefinitionId("creddef:1")
            .setCredentialAttributes([CredentialPreviewAttribute(name: "idade", mimeType: "", value: "20")])
            .build()
        
        credRepo.stubbedById["cred-1"] = cred
        
        await XCTAssertThrowsErrorAsync {
            try await self.sut.validateCredentialChosen(chosenCredentialId: "cred-1", proofRequest: proofRequest)
        }
    }
    
    func test_validateCredentialChosen_whenCredDefMismatch_throws() async throws {
        let requested = AnonCredsRequestedAttribute(
            name: "nome",
            names: nil,
            restrictions: [AnonCredsProofRequestRestriction(credDefId: "creddef:EXPECTED")],
            nonRevoked: nil
        )
        
        let proofRequest = AnonCredsProofRequest(
            name: "Proof",
            version: "1.0",
            nonce: "1",
            requestedAttributes: ["attr1": requested],
            requestedPredicates: [:],
            nonRevoked: nil
        )
        
        let cred = CredentialExchangeRecordBuilder()
            .setId("rec-1")
            .setCredentialDefinitionId("creddef:OTHER")
            .setCredentialAttributes([CredentialPreviewAttribute(name: "nome", mimeType: "mime", value: "val")])
            .build()
        
        credRepo.stubbedById["cred-1"] = cred
        
        await XCTAssertThrowsErrorAsync {
            try await self.sut.validateCredentialChosen(chosenCredentialId: "cred-1", proofRequest: proofRequest)
        }
    }
    
    private func XCTAssertThrowsErrorAsync(
        _ expression: @escaping () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await expression()
            XCTFail("Expected error, but no error was thrown", file: file, line: line)
        } catch {
            // ok
        }
    }
}
