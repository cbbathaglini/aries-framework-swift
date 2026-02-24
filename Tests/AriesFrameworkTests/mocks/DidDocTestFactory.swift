//
//  DummyDidDoc.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//
@testable import AriesFramework

enum DidDocTestFactory {

    static func minimal(
        did: String = "did:test:123",
        recipientKey: String = "GJ1SzoWzavQYfNL9XkaJdrQejfztN4XqdsiV4ct3LXKL"
    ) -> DidDoc {

        let publicKey = Ed25119Sig2018(
            id: "\(did)#key-1",
            controller: did,
            publicKeyBase58: recipientKey
        )

        let authentication = Authentication.referenced(
            ReferencedAuthentication(
                type: publicKey.type,
                publicKey: publicKey.id
            )
        )

        let recipientDidKey = (try? DIDParser.ConvertVerkeyToDidKey(verkey: recipientKey)) ?? recipientKey

        let service = DidDocService.indyAgent(
            IndyAgentService(
                id: "#IndyAgentService",
                serviceEndpoint: "http://localhost",
                recipientKeys: [recipientDidKey],
                routingKeys: []
            )
        )

        return DidDoc(
            id: did,
            publicKey: [publicKey],
            service: [service],
            authentication: [authentication]
        )
    }
}
