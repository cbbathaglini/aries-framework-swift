//
//  DeclineCredentialOfferOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation

public struct DeclineCredentialOfferOptions: Codable {
    public var sendProblemReport: Bool?
    public var problemReportDescription: String?

    public init(
        sendProblemReport: Bool? = false,
        problemReportDescription: String? = nil
    ) {
        self.sendProblemReport = sendProblemReport
        self.problemReportDescription = problemReportDescription
    }
}
