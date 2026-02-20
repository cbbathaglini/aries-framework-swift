
import Foundation
import os
import Base58Swift

public class JwsService {
    let agent: Agent
    let logger = Logger(subsystem: "AriesFramework", category: "JwsService")

    init(agent: Agent) {
        self.agent = agent
    }

    /**
     Creates a JWS using the given payload and verkey.

     - Parameters:
       - payload: The payload to sign.
       - verkey: The verkey to sign the payload for. The verkey should be created using ``Wallet.createDid(seed:)``.
     - Returns: A JWS object.
    */
    public func createJws(payload: Data, verkey: String) async throws -> JwsGeneralFormat {

        let jwk = try await agent.wallet.getJwkPublic(verkey: verkey)

        let protectedHeader: [String: Any] = [
            "alg": "EdDSA",
            "jwk": jwk
        ]

        let protectedData = try JSONSerialization.data(withJSONObject: protectedHeader)
        let base64Protected = protectedData.base64EncodedString().base64ToBase64url()
        let base64Payload = payload.base64EncodedString().base64ToBase64url()

        let message = "\(base64Protected).\(base64Payload)".data(using: .utf8)!

        let signature = try await agent.wallet.sign(
            data: message,
            verkey: verkey
        )

        return JwsGeneralFormat(
            header: ["kid": try DIDParser.ConvertVerkeyToDidKey(verkey: verkey)],
            signature: signature.base64EncodedString().base64ToBase64url(),
            protected: base64Protected
        )
    }

    /**
     Verifies the given JWS against the given payload.

     - Parameters:
       - jws: The JWS to verify.
       - payload: The payload to verify the JWS against.
     - Returns: A tuple containing the validity of the JWS and the signer's verkey.
    */
    public func verifyJws(jws: Jws, payload: Data) throws -> (isValid: Bool, signer: String) {

        let sig: JwsGeneralFormat = {
            switch jws {
            case .flattened(let list): return list.signatures.first!
            case .general(let jws): return jws
            }
        }()

        let protectedJson = Data(base64Encoded: sig.protected.base64urlToBase64())!
        let protected = try JSONSerialization.jsonObject(with: protectedJson) as! [String: Any]
        let jwk = protected["jwk"]!
        let jwkData = try JSONSerialization.data(withJSONObject: jwk)
        let jwkString = String(data: jwkData, encoding: .utf8)!

        let base64Payload = payload.base64EncodedString().base64ToBase64url()
        let message = "\(sig.protected).\(base64Payload)".data(using: .utf8)!

        let signature = Data(base64Encoded: sig.signature.base64urlToBase64())!

        let isValid = try agent.wallet.verify(
            message: message,
            signature: signature,
            jwk: jwkString
        )

        let signer = try agent.wallet.verkeyFromJwk(jwk: jwkString)

        return (isValid, signer)
    }
}
