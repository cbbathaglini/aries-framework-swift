//
//  ProofHandler.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 13/10/25.
//


import Foundation
import SwiftUI
import AriesFramework

@MainActor
class ProofHandler: ObservableObject {
    static let shared = ProofHandler()
    private init() {}
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    func generateProofRequest(
        agent: Agent,
        proofRequest: [String: Any],
        type: String = "online",
        connectionId: String? = nil
    ) async throws -> (request: AnonCredsProofRequest, qrImage: UIImage) {
        
        let requestedAttributes = try buildRequestedAttributes(from: proofRequest)
        let requestedPredicates = try buildRequestedPredicates(from: proofRequest)
        let nonce = try ProofServiceV2.generateProofRequestNonce()
        let nonrevoke = buildNonRevokedInterval(from: proofRequest)

        let anonCredsProofRequest = AnonCredsProofRequest(
            name: proofRequest["name"] as? String ?? "Generated Proof Request",
            version: "1.0",
            nonce: nonce,
            requestedAttributes: requestedAttributes,
            requestedPredicates: requestedPredicates,
            nonRevoked: nonrevoke
        )

        let proofFormats: [ProofFormatSpec] = [
            ProofFormatSpec(
                attachmentId: RequestPresentationMessageV2.ANONCREDS_PROOF_REQUEST_ATTACHMENT_ID,
                format: AnoncredsProofFormatService.ANONCREDS_PRESENTATION_REQUEST
            )
        ]

        var verifierRecord: VerifierRecord?

        // MARK: - OFFLINE MODE
        if connectionId == nil {
            let result = try await agent.proofCommandV2.requestProofOffline(
                proofRequest: anonCredsProofRequest,
                formats: proofFormats
            )
            
            verifierRecord = result.1
        }
        else {
            let result = try await agent.proofCommandV2.requestProof(
                connectionId: connectionId!,
                proofRequest: anonCredsProofRequest,
                formats: proofFormats
            )

            verifierRecord = result.1
        }

        guard let verifierRecord = verifierRecord else {
            throw CredoError("VerifierRecord is nil — proof request failed.")
        }

        guard let message = verifierRecord.requestMessage else {
            throw CredoError("VerifierRecord missing requestMessage")
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]

        let jsonData = try encoder.encode(message)

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw CredoError("Unable to convert requestMessage to UTF-8 string")
        }

        let qrImage = generateQRCode(from: jsonString)
        return (anonCredsProofRequest, qrImage)
    }
    
    
    func buildNonRevokedInterval(from dict: [String: Any]) -> AnonCredsNonRevokedInterval? {
        guard let interval = dict["interval"] as? [String: Any] else {
            return nil
        }
        
        guard let rawTo = interval["end"] else {
            return nil
        }
        
        
        let to: UInt64
        if let intVal = rawTo as? Int {
            to = UInt64(intVal)
        } else if let int64Val = rawTo as? UInt64 {
            to = int64Val
        } else if let strVal = rawTo as? String, let parsed = UInt64(strVal) {
            to = parsed
        } else {
            return nil
        }
        
        
        return AnonCredsNonRevokedInterval(from: 0, to: to)
    }
    
    private func buildRequestedAttributes(from proofRequest: [String: Any]) throws -> [String: AnonCredsRequestedAttribute] {
        guard let attributesList = proofRequest["attributes"] as? [[String: Any]] else {
            throw NSError(domain: "ProofHandler", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid attributes list"])
        }
        
        var requestedAttributes: [String: AnonCredsRequestedAttribute] = [:]
        
        for element in attributesList {
            var restrictions: [AnonCredsProofRequestRestriction]? = nil
            if let credDefId = element["credDefId"] as? String, !credDefId.isEmpty {
                restrictions = [AnonCredsProofRequestRestriction(credDefId: credDefId)]
            }
            
            let attrName = element["name"] as? String ?? ""
            var schemaName = element["schemaName"] as? String ?? ""
            
            if !attrName.isEmpty {
                if schemaName.isEmpty { schemaName = attrName }
                requestedAttributes[schemaName] = AnonCredsRequestedAttribute(
                    name: attrName,
                    restrictions: restrictions,
                    nonRevoked: nil
                )
            } else if let attrNames = element["names"] as? [String], !schemaName.isEmpty {
                requestedAttributes[schemaName] = AnonCredsRequestedAttribute(
                    names: attrNames,
                    restrictions: restrictions,
                    nonRevoked: nil
                )
            }
        }
        return requestedAttributes
    }
    
    private func buildRequestedPredicates(from proofRequest: [String: Any]) throws -> [String: AnonCredsRequestedPredicate] {
        var requestedPredicates: [String: AnonCredsRequestedPredicate] = [:]
        
        guard let predicatesList = proofRequest["predicates"] as? [[String: Any]] else { return requestedPredicates }
        
        for element in predicatesList {
            guard let attrName = element["name"] as? String, !attrName.isEmpty,
                  let predTypeStr = element["type"] as? String, !predTypeStr.isEmpty,
                  let rawValue = element["value"] else { continue }
            
            var restrictions: [AnonCredsProofRequestRestriction]? = nil
            if let credDefId = element["credDefId"] as? String, !credDefId.isEmpty {
                restrictions = [AnonCredsProofRequestRestriction(credDefId: credDefId)]
            }
            
            let numericValue = parsePredicateValue(rawValue) ?? 0
            let pType = try PredicateType.fromString(predTypeStr)
            
            print("📊 Predicate processed → \(attrName) \(predTypeStr) \(numericValue)")
            requestedPredicates[attrName] = AnonCredsRequestedPredicate(
                name: attrName,
                pType: pType,
                pValue: numericValue,
                restrictions: restrictions,
                nonRevoked: nil
            )
        }
        
        return requestedPredicates
    }
    
    func parsePredicateValue(_ value: Any) -> Int64? {

        if let int64 = value as? Int64 {
            return int64
        }

        if let intValue = value as? Int {
            return Int64(intValue)
        }

        if let str = value as? String, let intValue = Int64(str) {
            return intValue
        }

        return nil
    }
    

    private func encodeProofRequestToJSON(_ proofRequest: AnonCredsProofRequest) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(proofRequest)
        guard let json = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "ProofHandler", code: 501, userInfo: [NSLocalizedDescriptionKey: "Error encoding proof request to JSON"])
        }
        return json
    }

    private func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)
        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}
