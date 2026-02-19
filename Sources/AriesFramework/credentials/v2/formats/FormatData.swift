//
//  FormatData.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//
import AnyCodable
public class FormatData : Codable {
    var proposal: AnyCodable?
    var offer: AnyCodable?
    var request: AnyCodable?
    var credential: AnyCodable?

    init(proposal: AnyCodable? = nil, offer: AnyCodable? = nil, request: AnyCodable? = nil, credential: AnyCodable? = nil) {
        self.proposal = proposal
        self.offer = offer
        self.request = request
        self.credential = credential
    }
}
