//
//  CredentialFormatAnonCreds.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//
import AnyCodable
public class CredentialFormatAnonCreds: CredentialFormatOperations {
    public init(
        createProposal: AnonCredsProposeCredentialFormat,
        acceptProposal: AnonCredsAcceptProposalFormat,
        createOffer: AnonCredsOfferCredentialFormat,
        acceptOffer: AnonCredsAcceptOfferFormat,
        createRequest: AnyCodable? = nil,
        acceptRequest: AnonCredsAcceptRequestFormat
    ) throws {
        let createProposalCodable = AnyCodable(createProposal)
        let acceptProposalCodable = AnyCodable(acceptProposal)
        let createOfferCodable = AnyCodable(createOffer)
        let acceptOfferCodable = AnyCodable(acceptOffer)
        let acceptRequestCodable = AnyCodable(acceptRequest)

        super.init(
            createProposal: createProposalCodable,
            acceptProposal: acceptProposalCodable,
            createOffer: createOfferCodable,
            acceptOffer: acceptOfferCodable,
            createRequest: createRequest,
            acceptRequest: acceptRequestCodable
       
        )
    }
    
    required public init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
