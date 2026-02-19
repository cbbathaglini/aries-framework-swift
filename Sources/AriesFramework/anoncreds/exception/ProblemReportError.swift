//
//  ProblemReportError.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation

struct ProblemReportDescription: Codable {
    let en: String
    let code: String
}

struct ProblemReportMessageError: Codable {
    let description: ProblemReportDescription
}

public class ProblemReportError: CredoError {
    let problemReport: ProblemReportMessageError

    init(message: String, problemCode: String) {
        self.problemReport = ProblemReportMessageError(
            description: ProblemReportDescription(en: message, code: problemCode)
        )
        super.init(message)
    }
}
