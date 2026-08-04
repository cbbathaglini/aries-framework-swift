//
//  CredentialFormatOperations.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//
import AnyCodable

open class CredentialFormatOperations : Codable {
    public let createProposal: AnyCodable?
    public let acceptProposal: AnyCodable?
    public let createOffer: AnyCodable?
    public let acceptOffer: AnyCodable?
    public let createRequest: AnyCodable?
    public let acceptRequest: AnyCodable?

    public init(
        createProposal: AnyCodable?,
        acceptProposal: AnyCodable?,
        createOffer: AnyCodable?,
        acceptOffer: AnyCodable?,
        createRequest: AnyCodable? = nil,
        acceptRequest: AnyCodable?
    ) {
        self.createProposal = createProposal
        self.acceptProposal = acceptProposal
        self.createOffer = createOffer
        self.acceptOffer = acceptOffer
        self.createRequest = createRequest
        self.acceptRequest = acceptRequest
    }
}
