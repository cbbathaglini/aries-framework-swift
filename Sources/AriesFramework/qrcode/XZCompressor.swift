//
//  XZCompressor.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 11/03/26.
//

import Foundation
import PLzmaSDK

public enum XZCompressor {
    enum XZError: LocalizedError {
        case openFailed
        case compressFailed
        case outputDataUnavailable

        var errorDescription: String? {
            switch self {
            case .openFailed:
                return "Failed to open XZ encoder."
            case .compressFailed:
                return "Failed to compress XZ data."
            case .outputDataUnavailable:
                return "Could not read compressed data from memory OutStream."
            }
        }
    }

    static func compress(_ input: Data) throws -> Data {
        guard !input.isEmpty else { return Data() }

        let outStream = try OutStream()
        let encoder = try Encoder(
            stream: outStream,
            fileType: .xz,
            method: .LZMA2,
            delegate: nil
        )

        try encoder.setCompressionLevel(9)

        let inStream = try InStream(dataCopy: input)

        try encoder.add(stream: inStream, archivePath: Path("payload"))

        let opened = try encoder.open()
        guard opened else {
            throw XZError.openFailed
        }

        let compressed = try encoder.compress()
        guard compressed else {
            throw XZError.compressFailed
        }

        guard let data = try extractData(from: outStream) else {
            throw XZError.outputDataUnavailable
        }

        return data
    }

    private static func extractData(from outStream: OutStream) throws -> Data? {
        return try outStream.copyContent()
    }
}
