//
//  RecordUtils.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//
import Foundation

public struct RecordUtils {
    static func generateId() -> String {
        UUID().uuidString
    }
}
