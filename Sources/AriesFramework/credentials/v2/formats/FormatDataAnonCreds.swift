//
//  FormatDataAnonCreds.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//
import Foundation
import AnyCodable

public class FormatDataAnonCreds: FormatData {
    public let proposalData: AnonCredsCredentialProposalFormat
    public let offerData: AnonCredsCredentialOffer
    public let requestData: AnonCredsCredentialRequest
    public let credentialData: AnonCredsCredential
    
    public init(
           proposal: AnonCredsCredentialProposalFormat,
           offer: AnonCredsCredentialOffer,
           request: AnonCredsCredentialRequest,
           credential: AnonCredsCredential
       ) {
           self.proposalData = proposal
           self.offerData = offer
           self.requestData = request
           self.credentialData = credential
           super.init(
               proposal: AnyCodable(proposal),
               offer: AnyCodable(offer),
               request: AnyCodable(request),
               credential: AnyCodable(credential)
           )
    }
    required public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            proposalData = try container.decode(AnonCredsCredentialProposalFormat.self, forKey: .proposalData)
            offerData = try container.decode(AnonCredsCredentialOffer.self, forKey: .offerData)
            requestData = try container.decode(AnonCredsCredentialRequest.self, forKey: .requestData)
            credentialData = try container.decode(AnonCredsCredential.self, forKey: .credentialData)

            try super.init(from: decoder)
        }

        enum CodingKeys: String, CodingKey {
            case proposalData
            case offerData
            case requestData
            case credentialData
        }
}
