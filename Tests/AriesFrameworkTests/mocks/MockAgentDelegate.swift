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

    func onBasicMessageChanged(record: BasicMessageRecord) {
        receivedRecord = record
    }
}
