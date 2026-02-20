//
//  DispatcherProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

public protocol DispatcherProtocol {
    func registerHandler(handler: MessageHandler)
}

extension Dispatcher: DispatcherProtocol {}
