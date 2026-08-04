//
//  CredentialFormat.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//


public protocol CredentialFormat {
    var formatKey: String { get }
    var credentialRecordType: String { get }
    var credentialFormats: CredentialFormatOperations { get }
    var formatData: FormatData { get }
}
