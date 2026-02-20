//
//  MockBasicMessageHandlerAgent.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 20/02/26.
//

import Foundation
import AnyCodable
@testable import AriesFramework

final class MockBasicMessageHandlerAgent: BasicMessageHandlerAgentProtocol {

    var _basicMessageRepository: BasicMessageRepositoryProtocol!
    var _agentDelegate: AgentDelegate?

    var basicMessageRepository: BasicMessageRepositoryProtocol! { _basicMessageRepository }
    var agentDelegate: AgentDelegate? { _agentDelegate }
}
