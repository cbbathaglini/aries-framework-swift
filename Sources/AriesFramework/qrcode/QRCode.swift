//
//  QRCode.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 11/03/26.
//


import Foundation
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

public final class QRCode {

    private let context = CIContext()

    public init() {}

    public func buildQRCode(_ jsonString: String) throws -> [UIImage] {
        var qrList: [UIImage] = []

        let dataSize = 1024
        var start = 0
        var chunkId = 0

        let compressedData = try XZCompressor.compress(Data(jsonString.utf8))
        let qrData = Base91.encode([UInt8](compressedData))

        let total = Int(ceil(Double(qrData.count) / Double(dataSize)))

        while start < qrData.count {
            let end = min(start + dataSize, qrData.count)

            let startIndex = qrData.index(qrData.startIndex, offsetBy: start)
            let endIndex = qrData.index(qrData.startIndex, offsetBy: end)
            let payload = String(qrData[startIndex..<endIndex])

            let chunk = "\(chunkId)/\(total)\n\n\(payload)"
            chunkId += 1
            start = end

            guard let image = generateQRImage(from: chunk, size: 700) else {
                throw QRCodeError.failedToGenerateImage(chunkId: chunkId - 1)
            }

            qrList.append(image)
        }

        return qrList
    }

    private func generateQRImage(from string: String, size: CGFloat) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let scaleX = size / outputImage.extent.width
        let scaleY = size / outputImage.extent.height
        let transformed = outputImage.transformed(by: .init(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

public enum QRCodeError: LocalizedError {
    case failedToGenerateImage(chunkId: Int)

    public var errorDescription: String? {
        switch self {
        case .failedToGenerateImage(let chunkId):
            return "Failed to generate QR image for chunk \(chunkId)."
        }
    }
}
