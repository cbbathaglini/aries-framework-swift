//
//  MessageValidator.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation

enum MessageValidationError: Error, LocalizedError {
    case validationFailed(classType: String, validationErrors: [String])

    var errorDescription: String? {
        switch self {
        case .validationFailed(let classType, let errors):
            return "Failed to validate class '\(classType)': \(errors.joined(separator: ", "))"
        }
    }
}

class MessageValidator {

    static func validateSync(_ instance: Any) throws {
        let errors = validate(instance)

        if !errors.isEmpty {
            let classType = String(describing: type(of: instance))
            throw MessageValidationError.validationFailed(classType: classType, validationErrors: errors)
        }
    }

    private static func validate(_ obj: Any) -> [String] {
        var violations = [String]()

        if let proposal = obj as? AnonCredsCredentialProposal {
            if proposal.schemaName?.isEmpty ?? true {
                violations.append("schemaName must not be blank")
            }
        }

        return violations
    }
}
