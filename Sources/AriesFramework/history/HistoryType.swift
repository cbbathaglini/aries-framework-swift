//
//  HistoryType.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 01/10/25.
//

import Foundation

public enum HistoryType: String, Codable {
    case basicMessageReceived = "basic-message-received"
    case connectionCreated = "connection-created"
    case credentialOfferAccepted = "credential-offer-accepted"
    case credentialOfferDeclined = "credential-offer-declined"
    case credentialOfferReceived = "credential-offer-received"
    case credentialRevoked = "credential-revoked"
    case proofRequestAccepted = "proof-request-accepted"
    case proofRequestDeclined = "proof-request-declined"
    case proofRequestReceived = "proof-request-received"
}
