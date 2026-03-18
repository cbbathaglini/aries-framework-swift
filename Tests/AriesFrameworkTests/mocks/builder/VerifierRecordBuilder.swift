//
//  VerifierRecordBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/26.
//

import Foundation
import AnyCodable
@testable import AriesFramework

final class VerifierRecordBuilder {

    private var id: String = UUID().uuidString
    private var createdAt: Date = Date()
    private var updatedAt: Date? = nil
    private var tags: Tags? = nil
    private var metadata: [String: AnyCodable] = [:]

    private var offline: Bool = false
    private var globalThreadId: String? = nil
    private var proofRequest: AnonCredsProofRequest? = nil
    private var requestMessage: RequestPresentationMessageV2? = nil
    private var presentation: [PresentationVerifier]? = []

    @discardableResult
    func setId(_ value: String) -> Self {
        self.id = value
        return self
    }

    @discardableResult
    func setCreatedAt(_ value: Date) -> Self {
        self.createdAt = value
        return self
    }

    @discardableResult
    func setUpdatedAt(_ value: Date?) -> Self {
        self.updatedAt = value
        return self
    }

    @discardableResult
    func setTags(_ value: Tags?) -> Self {
        self.tags = value
        return self
    }

    @discardableResult
    func setMetadata(_ value: [String: AnyCodable]) -> Self {
        self.metadata = value
        return self
    }

    @discardableResult
    func setOffline(_ value: Bool) -> Self {
        self.offline = value
        return self
    }

    @discardableResult
    func setGlobalThreadId(_ value: String?) -> Self {
        self.globalThreadId = value
        return self
    }

    @discardableResult
    func setProofRequest(_ value: AnonCredsProofRequest?) -> Self {
        self.proofRequest = value
        return self
    }

    @discardableResult
    func setRequestMessage(_ value: RequestPresentationMessageV2?) -> Self {
        self.requestMessage = value
        return self
    }

    @discardableResult
    func setPresentation(_ value: [PresentationVerifier]?) -> Self {
        self.presentation = value
        return self
    }

    @discardableResult
    func addPresentation(_ value: PresentationVerifier) -> Self {
        if presentation == nil {
            presentation = []
        }
        presentation?.append(value)
        return self
    }

    func build() -> VerifierRecord {
        var record = VerifierRecord(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tags: tags,
            metadata: metadata,
            proofRequest: proofRequest,
            requestMessage: requestMessage,
            globalThreadId: globalThreadId,
            offline: offline
        )

        record.presentation = presentation
        return record
    }
}
