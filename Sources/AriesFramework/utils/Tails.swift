//
//  Tails.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 24/02/26.
//
import Foundation

class Tails {
        
    private static func baseURL(from raw: String) -> URL {
        if raw.hasPrefix("file://"), let u = URL(string: raw) { return u }     // ✅ file:///...
        return URL(fileURLWithPath: raw)                                       // ✅ /var/mobile/...
    }

    public static func findTailsFile(tailsFilePath rawBase: String, tailsHash: String) -> URL? {
        let fm = FileManager.default

        // absolte path (old way)
        let savedBase = baseURL(from: rawBase)
        let saved = savedBase.appendingPathComponent(tailsHash)
        if fm.fileExists(atPath: saved.path) { return saved }

        // tenta Documents/tails
        if let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
            let docsTails = docs.appendingPathComponent("tails", isDirectory: true)
            let f = docsTails.appendingPathComponent(tailsHash)
            if fm.fileExists(atPath: f.path) { return f }
        }

        // Application Support/tails
        if let appSup = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let appTails = appSup.appendingPathComponent("tails", isDirectory: true)
            let f = appTails.appendingPathComponent(tailsHash)
            if fm.fileExists(atPath: f.path) { return f }
        }

        return nil
    }
}

