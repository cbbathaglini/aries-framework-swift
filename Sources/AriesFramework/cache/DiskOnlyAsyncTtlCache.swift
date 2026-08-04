//
//  DiskOnlyAsyncTtlCache.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 03/02/26.
//

import Foundation
import CryptoKit


public actor DiskOnlyAsyncTtlCache<K: Hashable, V: Codable> {


    private struct DiskEntry: Codable {
        let valueJson: String
        let expiresAt: Int64
    }

    public struct CacheHit<Value> {
        public let value: Value
        public let expiresAtMillis: Int64

        public var expiresAtDate: Date {
            Date(timeIntervalSince1970: TimeInterval(expiresAtMillis) / 1000.0)
        }
    }

    private let cacheName: String
    public let ttlMillis: Int64

    private let keyToString: (K) -> String
    private let nowMillis: () -> Int64

    private var inFlight: [K: Task<V, Error>] = [:]

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private lazy var dirURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base
            .appendingPathComponent("ttl_cache", isDirectory: true)
            .appendingPathComponent(cacheName, isDirectory: true)

        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    // MARK: - Init

    public init(
        cacheName: String,
        ttlMillis: Int64,
        keyToString: @escaping (K) -> String,
        nowMillis: @escaping () -> Int64 = { Int64(Date().timeIntervalSince1970 * 1000) }
    ) {
        self.cacheName = cacheName
        self.ttlMillis = ttlMillis
        self.keyToString = keyToString
        self.nowMillis = nowMillis
    }

    // MARK: - Public API

    public func getOrLoad(_ key: K, loader: @escaping () async throws -> V) async throws -> V {
        if let fresh = try await readFromDiskIfFresh(key) {
            return fresh
        }

        if let existing = inFlight[key] {
            return try await existing.value
        }

        let task = Task<V, Error> {
            let value = try await loader()
            let expiresAt = nowMillis() + ttlMillis
            try await writeToDisk(key, value: value, expiresAt: expiresAt)
            return value
        }

        inFlight[key] = task

        do {
            let value = try await task.value
            inFlight[key] = nil
            return value
        } catch {
            inFlight[key] = nil
            throw error
        }
    }

    public func getOrLoadWithMeta(_ key: K, loader: @escaping () async throws -> V) async throws -> CacheHit<V> {
        if let hit = try await readFromDiskIfFreshWithMeta(key) {
            return hit
        }

        if let existing = inFlight[key] {
            let value = try await existing.value
            if let hit = try await readFromDiskIfFreshWithMeta(key) {
                return hit
            }
        
            return CacheHit(value: value, expiresAtMillis: nowMillis() + ttlMillis)
        }

        let task = Task<V, Error> {
            let value = try await loader()
            let expiresAt = nowMillis() + ttlMillis
            try await writeToDisk(key, value: value, expiresAt: expiresAt)
            return value
        }

        inFlight[key] = task

        do {
            let _ = try await task.value
            inFlight[key] = nil

            if let hit = try await readFromDiskIfFreshWithMeta(key) {
                return hit
            }

            let valueFromDisk = try await readFromDiskIfFresh(key)

            if let value = valueFromDisk {
                return CacheHit(
                    value: value,
                    expiresAtMillis: nowMillis() + ttlMillis
                )
            }

            let value = try await task.value
            return CacheHit(
                value: value,
                expiresAtMillis: nowMillis() + ttlMillis
            )
        } catch {
            inFlight[key] = nil
            throw error
        }
    }

    public func getIfFresh(_ key: K) async -> V? {
        do { return try await readFromDiskIfFresh(key) }
        catch { return nil }
    }

    public func getIfFreshWithMeta(_ key: K) async -> CacheHit<V>? {
        do { return try await readFromDiskIfFreshWithMeta(key) }
        catch { return nil }
    }


    public func getExpiresAtIfFresh(_ key: K) async -> Date? {
        do {
            guard let hit = try await readFromDiskIfFreshWithMeta(key) else { return nil }
            return hit.expiresAtDate
        } catch {
            return nil
        }
    }

    public func invalidate(_ key: K) async {
        let url = fileURL(for: key)
        try? FileManager.default.removeItem(at: url)
    }

    public func clear() async {
        let fm = FileManager.default
        let url = dirURL
        let files = (try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
        for f in files {
            try? fm.removeItem(at: f)
        }
    }

    public func pruneExpired() async {
        let fm = FileManager.default
        let url = dirURL
        let files = (try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
        for f in files {
            do {
                let data = try Data(contentsOf: f)
                let entry = try decoder.decode(DiskEntry.self, from: data)
                if nowMillis() >= entry.expiresAt {
                    try? fm.removeItem(at: f)
                }
            } catch {
                try? fm.removeItem(at: f)
            }
        }
    }

    // MARK: - Disk IO

    private func fileURL(for key: K) -> URL {
        let raw = keyToString(key)
        let safe = sha256(raw)
        return dirURL.appendingPathComponent("\(safe).json", isDirectory: false)
    }

    private func readFromDiskIfFresh(_ key: K) async throws -> V? {
        try await readFromDiskIfFreshWithMeta(key)?.value
    }

    private func readFromDiskIfFreshWithMeta(_ key: K) async throws -> CacheHit<V>? {
        let url = fileURL(for: key)

        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let entry = try decoder.decode(DiskEntry.self, from: data)

            if nowMillis() >= entry.expiresAt {
                try? FileManager.default.removeItem(at: url)
                return nil
            }

            guard let valueData = entry.valueJson.data(using: .utf8) else {
                try? FileManager.default.removeItem(at: url)
                return nil
            }

            let value = try decoder.decode(V.self, from: valueData)
            return CacheHit(value: value, expiresAtMillis: entry.expiresAt)
        } catch {
            try? FileManager.default.removeItem(at: url)
            return nil
        }
    }

    private func writeToDisk(_ key: K, value: V, expiresAt: Int64) async throws {
        let url = fileURL(for: key)

        let valueData = try encoder.encode(value)
        let valueJson = String(data: valueData, encoding: .utf8) ?? "{}"

        let entry = DiskEntry(valueJson: valueJson, expiresAt: expiresAt)
        let payload = try encoder.encode(entry)

        try payload.write(to: url, options: [.atomic])
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
