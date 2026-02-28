//
//  ProofExchangeRecordBuilder.swift
//  aries-framework-swiftTests
//

import Foundation
import AnyCodable
@testable import AriesFramework

final class ProofExchangeRecordBuilder {

    private var id: String = UUID().uuidString
    private var createdAt: Date = Date()
    private var updatedAt: Date? = nil
    private var tags: Tags? = nil
    private var metadata: [String: AnyCodable] = [:]

    private var connectionId: String = ""
    private var threadId: String = UUID().uuidString
    private var parentThreadId: String? = nil

    private var isVerified: Bool? = nil
    private var presentationId: String? = nil

    private var state: ProofState = .ProposalSent
    private var role: ProofRole = .prover
    private var autoAcceptProof: AutoAcceptProof? = nil

    private var errorMessage: String? = nil
    private var comment: String? = nil

    private var protocolVersion: String = "v2"
    private var formats: [ProofFormatSpec] = []

    private var proofRequestVerifierJson: String? = nil
    private var proofPresentationVerifierJson: String? = nil
    private var presentationMessage: PresentationMessageV2? = nil
    private var chosenCredentialId: String? = nil

    // MARK: - Setters (fluent)

    @discardableResult func setId(_ v: String) -> Self { id = v; return self }
    @discardableResult func setCreatedAt(_ v: Date) -> Self { createdAt = v; return self }
    @discardableResult func setUpdatedAt(_ v: Date?) -> Self { updatedAt = v; return self }
    @discardableResult func setTags(_ v: Tags?) -> Self { tags = v; return self }
    @discardableResult func setMetadata(_ v: [String: AnyCodable]) -> Self { metadata = v; return self }

    @discardableResult func setConnectionId(_ v: String) -> Self { connectionId = v; return self }
    @discardableResult func setThreadId(_ v: String) -> Self { threadId = v; return self }
    @discardableResult func setParentThreadId(_ v: String?) -> Self { parentThreadId = v; return self }

    @discardableResult func setIsVerified(_ v: Bool?) -> Self { isVerified = v; return self }
    @discardableResult func setPresentationId(_ v: String?) -> Self { presentationId = v; return self }

    @discardableResult func setState(_ v: ProofState) -> Self { state = v; return self }
    @discardableResult func setRole(_ v: ProofRole) -> Self { role = v; return self }
    @discardableResult func setAutoAcceptProof(_ v: AutoAcceptProof?) -> Self { autoAcceptProof = v; return self }

    @discardableResult func setErrorMessage(_ v: String?) -> Self { errorMessage = v; return self }
    @discardableResult func setComment(_ v: String?) -> Self { comment = v; return self }

    @discardableResult func setProtocolVersion(_ v: String) -> Self { protocolVersion = v; return self }
    @discardableResult func setFormats(_ v: [ProofFormatSpec]) -> Self { formats = v; return self }

    @discardableResult func setProofRequestVerifierJson(_ v: String?) -> Self { proofRequestVerifierJson = v; return self }
    @discardableResult func setProofPresentationVerifierJson(_ v: String?) -> Self { proofPresentationVerifierJson = v; return self }
    @discardableResult func setPresentationMessage(_ v: PresentationMessageV2?) -> Self { presentationMessage = v; return self }
    @discardableResult func setChosenCredentialId(_ v: String?) -> Self { chosenCredentialId = v; return self }

    // MARK: - Build

    func build() -> ProofExchangeRecord {
        ProofExchangeRecord(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tags: tags,
            metadata: metadata,
            connectionId: connectionId,
            threadId: threadId,
            parentThreadId: parentThreadId,
            isVerified: isVerified,
            presentationId: presentationId,
            state: state,
            role: role,
            autoAcceptProof: autoAcceptProof,
            errorMessage: errorMessage,
            comment: comment,
            protocolVersion: protocolVersion,
            formats: formats,
            proofRequestVerifierJson: proofRequestVerifierJson,
            proofPresentationVerifierJson: proofPresentationVerifierJson,
            presentationMessage: presentationMessage,
            chosenCredentialId: chosenCredentialId
        )
    }
}
