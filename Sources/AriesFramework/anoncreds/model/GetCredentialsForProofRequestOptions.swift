//
//  GetCredentialsForProofRequestOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct GetCredentialsForProofRequestOptions: Codable {
    public var proofRequest: AnonCredsProofRequest
    public var attributeReferent: String
    public var start: Int?
    public var limit: Int?
    public var extraQuery: ReferentWalletQuery?
    public var chosenCredentialId: String? = nil
}
