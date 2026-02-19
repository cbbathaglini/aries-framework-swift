//
//  AnonCredsModuleConfigOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation

public class AnonCredsModuleConfigOptions {

    public let registries: [AnonCredsRegistry]
    public let tailsFileService: TailsFileService?
    public let anoncreds: Any?
    public let autoCreateLinkSecret: Bool

    public init(
        registries: [AnonCredsRegistry] = [EthrAnonCredsRegistry()],
        tailsFileService: TailsFileService? = nil,
        anoncreds: Any? = nil,
        autoCreateLinkSecret: Bool = true
    ) {
        self.registries = registries
        self.tailsFileService = tailsFileService
        self.anoncreds = anoncreds
        self.autoCreateLinkSecret = autoCreateLinkSecret
    }
}
