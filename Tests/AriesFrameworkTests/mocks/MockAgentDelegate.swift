//
//  MockAgentDelegate.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 20/02/26.
//

import Foundation
import AnyCodable
@testable import AriesFramework

final class MockAgentDelegate: AgentDelegate {

    var receivedRecord: BasicMessageRecord?
    private(set) var receivedProofStateChanges: [ProofExchangeRecord] = []

    func onBasicMessageChanged(record: BasicMessageRecord) {
        receivedRecord = record
    }
    
    func onProofStateChangedV2(proofRecord: ProofExchangeRecord) {
        receivedProofStateChanges.append(proofRecord)
    }
    
}
