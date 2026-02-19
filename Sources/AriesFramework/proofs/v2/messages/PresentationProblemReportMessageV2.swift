//
//  PresentationProblemReportMessageV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

import Foundation

public class PresentationProblemReportMessageV2: BaseProblemReportMessage {
    public static let type = "https://didcomm.org/present-proof/2.0/problem-report"

    public var proofRecord: ProofExchangeRecord?

    // MARK: - Designated initializer
    public init(
        threadId: String,
        descriptionOptions: DescriptionOptions = DescriptionOptions(en: "Proof abandoned", code: "abandoned"),
        proofRecord: ProofExchangeRecord? = nil
    ) {
        self.proofRecord = proofRecord
        super.init(description: descriptionOptions, fixHint: nil, type: PresentationProblemReportMessageV2.type)
        self.thread = ThreadDecorator(threadId: threadId)
    }

    // MARK: - Convenience initializer
    public convenience init(threadId: String) {
        self.init(
            threadId: threadId,
            descriptionOptions: DescriptionOptions(en: "Proof abandoned", code: "abandoned"),
            proofRecord: nil
        )
    }

    // MARK: - Decoder initializer (required for Codable)
    public required init(from decoder: Decoder) throws {
        self.proofRecord = nil
        try super.init(from: decoder)
        self.type = PresentationProblemReportMessageV2.type
    }
}
