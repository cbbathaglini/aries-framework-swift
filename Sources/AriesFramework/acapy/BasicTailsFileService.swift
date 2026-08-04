//
//  BasicTailsFileService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation
import CryptoKit
import os

public class BasicTailsFileService: TailsFileService {
    private let agent: Agent
    
    private let logger = Logger(subsystem: "org.hyperledger.ariesframework", category: "BasicTailsFileService")

    private let tailsDirectoryPath: String? = nil

    public init(agent: Agent) {
        self.agent = agent
    }

    public func getTailsBasePath() async throws -> String {
        let basePath = "\(tailsDirectoryPath ?? getDefaultCachePath())/anoncreds/tails"
        let fileDir = URL(fileURLWithPath: basePath).appendingPathComponent("file")

        if !FileManager.default.fileExists(atPath: fileDir.path) {
            try FileManager.default.createDirectory(at: fileDir, withIntermediateDirectories: true)
        }

        return basePath
    }

    private func getDefaultCachePath() -> String {
        return FileManager.default.temporaryDirectory.path
    }

    public func uploadTailsFile(options: UploadTailsFileOptions) async throws -> UploadTailsFileResult {
        throw AnonCredsError("BasicTailsFileService only supports tails file downloading")
    }

    public func getTailsFile(options: GetTailsFileOptions) async throws -> GetTailsFileResult {
        let revocationRegistryDefinition = options.revocationRegistryDefinition
        let tailsLocation = revocationRegistryDefinition.value.tailsLocation
        let tailsHash = revocationRegistryDefinition.value.tailsHash

        let tailsFilePath = try await getTailsFilePath(tailsHash: tailsHash)
        let tailsExists = try await tailsFileExists(tailsHash: tailsHash)

        if !tailsExists {
            logDebug("Downloading tails file from \(tailsLocation)")
            try downloadToFileWithSha256Check(
                url: tailsLocation,
                targetPath: tailsFilePath,
                expectedHashBase58: tailsHash
            )
            logDebug("Saved tails file to path: \(tailsFilePath)")
        }

        return GetTailsFileResult(tailsFilePath: tailsFilePath)
    }

    private func downloadToFileWithSha256Check(url: String, targetPath: String, expectedHashBase58: String) throws {
        guard let url = URL(string: url) else {
            throw AnonCredsError("Invalid tails file URL: \(url)")
        }

        let data = try Data(contentsOf: url)
        let computedHash = SHA256.hash(data: data)
        let actualHashBytes = Data(computedHash)

        let expectedHashBytes = try Base58.decode(expectedHashBase58)

        guard actualHashBytes == Data(expectedHashBytes) else {
            throw AnonCredsError("SHA-256 hash does not match expected Base58 hash")
        }

        let targetURL = URL(fileURLWithPath: targetPath)
        try data.write(to: targetURL)
    }

    private func downloadFile(url: String, targetPath: String) throws {
        guard let fileURL = URL(string: url) else {
            throw AnonCredsError("Invalid download URL")
        }
        let data = try Data(contentsOf: fileURL)
        try data.write(to: URL(fileURLWithPath: targetPath))
    }

    private func getTailsFilePath(tailsHash: String) async throws -> String {
        let basePath = try await getTailsBasePath()
        return "\(basePath)/\(tailsHash)"
    }

    private func tailsFileExists(tailsHash: String) async throws -> Bool {
        let path = try await getTailsFilePath(tailsHash: tailsHash)
        return FileManager.default.fileExists(atPath: path)
    }
}
