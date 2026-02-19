//
//  PresentationProblemReportErrorV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

public class PresentationProblemReportErrorV2: ProblemReportError {
    public let problemReportError: PresentationProblemReportMessageV2

    public init(
        message: String,
        problemCode: String,
        threadId: String,
        proofRecord: ProofExchangeRecord? = nil
    ) {
        self.problemReportError = PresentationProblemReportMessageV2(
            threadId: threadId,
            descriptionOptions: DescriptionOptions(
                en: message,
                code: problemCode
            ),
            proofRecord: proofRecord
        )

        super.init(message: message, problemCode: problemCode)
    }
}
