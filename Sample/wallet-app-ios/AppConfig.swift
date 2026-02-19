//
//  AppConfig.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 03/02/26.
//
import SwiftUI
import AriesFramework

enum AppConfig {
    
    static func string(_ key: String) -> String {
        guard var value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            fatalError("\(key) not found in Info.plist")
        }

        value = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
            value = String(value.dropFirst().dropLast())
        }

        return value
    }

    static func int(_ key: String, default defaultValue: Int) -> Int {
        let s = string(key)
        return Int(s.trimmingCharacters(in: .whitespacesAndNewlines)) ?? defaultValue
    }
}
