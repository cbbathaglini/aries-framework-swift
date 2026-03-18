//
//  PresentationAckMessageV2Builder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 16/03/26.
//

import Foundation
@testable import AriesFramework

final class PresentationAckMessageV2Builder {

    private var id: String? = nil
    private var threadId: String = UUID().uuidString
    private var status: AckStatus = .OK
    private var parentThreadId: String? = nil

    @discardableResult
    func setId(_ value: String?) -> Self {
        self.id = value
        return self
    }

    @discardableResult
    func setThreadId(_ value: String) -> Self {
        self.threadId = value
        return self
    }

    @discardableResult
    func setParentThreadId(_ value: String?) -> Self {
        self.parentThreadId = value
        return self
    }

    @discardableResult
    func setStatus(_ value: AckStatus) -> Self {
        self.status = value
        return self
    }

    func build() -> PresentationAckMessageV2 {
        let message = PresentationAckMessageV2(
            id: id,
            threadId: threadId,
            status: status
        )

        if parentThreadId != nil {
            message.setThread(
                threadId: threadId,
                parentThreadId: parentThreadId
            )
        }

        return message
    }
}
