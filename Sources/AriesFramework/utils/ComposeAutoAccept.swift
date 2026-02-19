//
//  ComposeAutoAccept.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

public func composeAutoAccept(
    recordConfig: AutoAcceptCredential?,
    agentConfig: AutoAcceptCredential?
) -> AutoAcceptCredential {
    return recordConfig ?? agentConfig ?? .never
}
