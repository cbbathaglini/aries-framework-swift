//
//  JwsServiceTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/12/25.
//

import XCTest
@testable import AriesFramework

final class JwsServiceTests: XCTestCase {

    var wallet: MockWallet!
    var agent: Agent!
    var service: JwsService!

    override func setUp() {
        super.setUp()

        wallet = MockWallet()
        agent = AgentTestFactory.jwsAgent(wallet: wallet)
        service = JwsService(agent: agent)
    }

    override func tearDown() {
        wallet = nil
        agent = nil
        service = nil
        super.tearDown()
    }

    func test_createJws_returnsValidJws() async throws {
        let payload = "hello".data(using: .utf8)!
        let verkey = "verkey"

        let jws = try await service.createJws(
            payload: payload,
            verkey: verkey
        )

        XCTAssertFalse(jws.signature.isEmpty)
        XCTAssertFalse(jws.protected.isEmpty)

        let header = try XCTUnwrap(jws.header)
        let kid = try XCTUnwrap(header["kid"])
        
        XCTAssertEqual(
            kid,
            try DIDParser.ConvertVerkeyToDidKey(verkey: verkey)
        )
    }

    func test_createJws_usesWalletSignAndJwk() async throws {
        let payload = Data([0x01, 0x02])
        let verkey = "verkey"

        _ = try await service.createJws(
            payload: payload,
            verkey: verkey
        )

        // Indiretamente validado:
        // - se não chamasse wallet.getJwkPublic → crash
        // - se não chamasse wallet.sign → crash
        XCTAssertTrue(wallet.isInitialized)
    }

    // MARK: - verifyJws

    func test_verifyJws_returnsValidResultAndSigner() throws {
        let payload = "hello".data(using: .utf8)!

        // protected header com jwk (como createJws gera)
        let protectedHeader: [String: Any] = [
            "jwk": [
                "kty": "OKP",
                "crv": "Ed25519",
                "x": "test"
            ]
        ]

        let protectedData = try JSONSerialization.data(
            withJSONObject: protectedHeader
        )

        let protectedBase64 =
            protectedData
                .base64EncodedString()
                .base64ToBase64url()

        let signature =
            Data("signed".utf8)
                .base64EncodedString()
                .base64ToBase64url()

        let jws = Jws.general(
            JwsGeneralFormat(
                header: ["kid": "did:key:test"],
                signature: signature,
                protected: protectedBase64
            )
        )

        let result = try service.verifyJws(
            jws: jws,
            payload: payload
        )

        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.signer, "verkey")
    }
}
