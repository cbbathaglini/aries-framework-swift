
import Foundation
import os
import askar_uniffi
import Base58Swift

public struct SignatureDecorator {
    var signatureType: String
    var signatureData: String
    var signer: String
    var signature: String
}

extension SignatureDecorator: CustomStringConvertible {
    public var description: String {
        return "SignatureDecorator\nsignatureType: \(signatureType)\nsignatureData: \(signatureData)\nsigner: \(signer)\nsignature: \(signature)"
    }
}

extension SignatureDecorator: Codable {
    enum CodingKeys: String, CodingKey {
        case signatureType = "@type", signatureData = "sig_data", signer = "signer", signature = "signature"
    }

    func unpackData() async throws -> Data {
        guard var signedData = Data(base64Encoded: signatureData.base64urlToBase64()), signedData.count > 8 else {
            throw AriesFrameworkError.frameworkError("Invalid signature data")
        }

        guard let signature = Data(base64Encoded: signature.base64urlToBase64()) else {
            throw AriesFrameworkError.frameworkError("Invalid signature")
        }

        let signerBytes: [UInt8]
        do {
            signerBytes = try Base58.decode(signer)
        } catch {
            throw AriesFrameworkError.frameworkError("Invalid signer: \(signer)")
        }
        
        let signKey = try LocalKeyFactory().fromPublicBytes(alg: .ed25519, bytes: Data(signerBytes))
        let isValid = try signKey.verifySignature(message: signedData, signature: signature, sigType: nil)
        if !isValid {
            throw AriesFrameworkError.frameworkError("Signature verification failed")
        }

        signedData = signedData.subdata(in: 8..<signedData.count)
        return signedData
    }

    func unpackConnection() async throws -> Connection {
        let signedData = try await unpackData()
        let connection = try JSONDecoder().decode(Connection.self, from: signedData)
        return connection
    }

    static func signData(
        data: Data,
        wallet: WalletProtocol,
        verkey: String
    ) async throws -> SignatureDecorator {

        var signatureData = Data(count: 8)
        signatureData.append(data)

        let signatureBytes = try await wallet.sign(
            data: signatureData,
            verkey: verkey
        )

        return SignatureDecorator(
            signatureType: "https://didcomm.org/signature/1.0/ed25519Sha512_single",
            signatureData: signatureData
                .base64EncodedString()
                .base64ToBase64url(),
            signer: verkey,
            signature: Data(signatureBytes)
                .base64EncodedString()
                .base64ToBase64url()
        )
    }
}
