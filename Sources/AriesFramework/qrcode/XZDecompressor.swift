//
//  XZDecompressor.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 11/03/26.
//

import Foundation
import PLzmaSDK

public enum XZDecompressor {
    enum XZError: LocalizedError {
        case openFailed
        case noItemsFound
        case extractFailed
        case outputDataUnavailable

        var errorDescription: String? {
            switch self {
            case .openFailed:
                return "Failed to open XZ decoder."
            case .noItemsFound:
                return "No items found inside XZ stream."
            case .extractFailed:
                return "Failed to extract XZ payload."
            case .outputDataUnavailable:
                return "Could not read decompressed data from memory OutStream."
            }
        }
    }

    public static func decompress(_ input: Data) throws -> Data {
        guard !input.isEmpty else { return Data() }

        let inStream = try InStream(dataNoCopy: input)
        let decoder = try Decoder(
            stream: inStream,
            fileType: .xz,
            delegate: nil
        )

        let opened = try decoder.open()
        guard opened else {
            throw XZError.openFailed
        }

        let count = try decoder.count()
        guard count > 0 else {
            throw XZError.noItemsFound
        }

        let item = try decoder.item(at: 0)
        let outStream = try OutStream()
        let itemsToStreams = try ItemOutStreamArray()
        try itemsToStreams.add(item: item, stream: outStream)

        let extracted = try decoder.extract(itemsToStreams: itemsToStreams)
        guard extracted else {
            throw XZError.extractFailed
        }

        guard let data = try extractData(from: outStream) else {
            throw XZError.outputDataUnavailable
        }

        return data
    }

    private static func extractData(from outStream: OutStream) throws -> Data?  {
        return try outStream.copyContent()
    }
}
