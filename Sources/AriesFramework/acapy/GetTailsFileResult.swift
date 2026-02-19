//
//  GetTailsFileResult.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//


public struct GetTailsFileResult: Codable {
    public let tailsFilePath: String

    public init(tailsFilePath: String) {
        self.tailsFilePath = tailsFilePath
    }
}
