# Aries Framework Swift

Aries Framework Swift is an iOS framework for [Aries](https://github.com/hyperledger/aries) protocol.

## Features

Aries Framework Swift supports most of [AIP 1.0](https://github.com/hyperledger/aries-rfcs/tree/main/concepts/0302-aries-interop-profile#aries-interop-profile-version-10) features for mobile agents.

### Supported features
- ✅ ([RFC 0160](https://github.com/hyperledger/aries-rfcs/blob/master/features/0160-connection-protocol/README.md)) Connection Protocol
- ✅ ([RFC 0037](https://github.com/hyperledger/aries-rfcs/tree/master/features/0037-present-proof/README.md)) Present Proof Protocol v1.0
- ✅ ([RFC 0454](https://github.com/hyperledger/aries-rfcs/blob/main/features/0454-present-proof-v2/README.md)) Present Proof Protocol v2.0 (message family `present-proof-v2`)
- ✅ ([RFC 0036](https://github.com/hyperledger/aries-rfcs/blob/master/features/0036-issue-credential/README.md)) Issue Credential Protocol v1.0
- ✅ ([RFC 0453](https://github.com/hyperledger/aries-rfcs/blob/main/features/0453-issue-credential-v2/README.md)) Issue Credential Protocol v2.0 (message family `issue-credential-v2`)
- ✅ ([RFC 0023](https://github.com/hyperledger/aries-rfcs/tree/main/features/0023-did-exchange)) DID Exchange Protocol (AIP 2.0)
- ✅ ([RFC 0434](https://github.com/hyperledger/aries-rfcs/blob/main/features/0434-outofband/README.md)) Out of Band Protocol (AIP 2.0)
  - Includes Handshake Reuse and Handshake Reuse Accepted messages
- ✅ ([RFC 0211](https://github.com/hyperledger/aries-rfcs/blob/master/features/0211-route-coordination/README.md)) Mediator Coordination Protocol
- ✅ ([RFC 0212](https://github.com/hyperledger/aries-rfcs/blob/master/features/0212-route-coordination-protocol/README.md)) (Mediator) Pickup Protocol v1 (`messagepickup`)
- ✅ ([RFC 0094](https://github.com/hyperledger/aries-rfcs/blob/main/features/0094-cross-domain-messaging/README.md)) Forward Protocol (`forward`)
- ✅ ([RFC 0048](https://github.com/hyperledger/aries-rfcs/blob/main/features/0048-trust-ping/README.md)) Trust Ping Protocol
- ✅ ([RFC 0095](https://github.com/hyperledger/aries-rfcs/blob/master/features/0095-basic-message/README.md)) Basic Message Protocol
- ✅ ([RFC 0035](https://github.com/hyperledger/aries-rfcs/blob/main/features/0035-report-problem/README.md)) Report Problem Protocol
- ✅ ([RFC 0452](https://github.com/hyperledger/aries-rfcs/blob/main/features/0452-credential-revocation-notification/README.md)) Credential Revocation Notification (v1 and v2)
- ✅ W3C Verifiable Credentials (JSON-LD) — W3C VC Data Model, `w3c` credential service and repository
- ✅ HTTP and WebSocket Transport

### Not supported yet
- ❌ ([RFC 0056](https://github.com/hyperledger/aries-rfcs/blob/main/features/0056-service-decorator/README.md)) Service Decorator

## Requirements & Installation

Aries Framework Swift requires iOS 15.0+ and distributed as a Swift package.

Add a dependency to your `Package.swift` file:
```swift
dependencies: [
    .package(url: "https://github.com/hyperledger/aries-framework-swift", from: "2.5.0")
]
```

## Usage

App development using Aries Framework Swift is done in the following steps:
1. Create an Agent instance
2. Create a connection with another agent by receiving a connection invitation (or an out-of-band invitation)
3. Receive out-of-band invitations, credentials and proof requests by implementing an `AgentDelegate`

### Create an Agent instance

```swift
import AriesFramework

let config = AgentConfig(
    walletKey: key,
    genesisPath: genesisPath,
    mediatorConnectionsInvite: mediatorInvitationUrl,
    mediatorPickupStrategy: .PickUpV1,
    label: "SwiftFrameworkAgent",
    autoAcceptCredential: .never,
    autoAcceptProof: .never
)

let agent = Agent(agentConfig: config, agentDelegate: myAgentDelegate)
try await agent.initialize()
```

To create an agent, first create a key to encrypt the wallet and save it securely (e.g. in the keychain or `UserDefaults`).
```swift
let key = try Agent.generateWalletKey()
```

A genesis file for the Indy pool should be included as a resource in the app bundle and its path passed to the config.
```swift
let genesisPath = Bundle.main.path(forResource: "genesis", ofType: "txn")
```

`agentDelegate` can be `nil` if you don't want to receive any events from the agent.

#### Using the Besu ledger (multi-ledger)

The framework can talk to a Besu ledger (AnonCreds objects stored on the Ethereum-based Besu ledger) instead of, or in addition to, an Indy ledger. This is configured through `useBesuLedger` and a `BesuLedgerConfig` that supports multi-ledger setup.

```swift
let besuAccounts = BesuLedgerConfig(
    configFile: "besu_config.json",
    multiledger: true
)

let config = AgentConfig(
    walletKey: key,
    genesisPath: genesisPath,
    label: "SampleAgent",
    useLedgerService: false,
    useBesuLedger: true,
    besuLedgerConfig: besuAccounts,
    cacheConfigFile: "cache_config.json"
)
```

- `useBesuLedger: true` enables the Besu ledger connector (`BesuLedgerService`).
- `besuLedgerConfig.multiledger: true` allows connecting to more than one ledger (each configured in the config file).
- The `besu_config.json` resource lists the networks (chain id, node address and the registry contracts, e.g. `ethereumDidRegistry`, `schemaRegistry`, `credentialDefinitionRegistry`, `revocationRegistry`).
- `cacheConfigFile` optionally points to a cache configuration used by `CacheOperations`.

> Note: to use the Besu ledger you must first build the `uniffi` bindings from
> [`indy-besu`](https://github.com/hyperledger-indy/indy-besu) and place them under `packages`,
> as described in the ["Using the Besu ledger"](#using-the-besu-ledger) section below.

If you want to use a mediator, set `mediatorConnectionsInvite` and `mediatorPickupStrategy` in the config.
`mediatorConnectionsInvite` is a URL containing either a connection invitation or an out-of-band invitation. `mediatorPickupStrategy` (`.PickUpV1` or `.Implicit`) controls how messages are picked up from the mediator; use `.Implicit` to connect to an ACA-Py mediator.

You can use WebSocket transport without a mediator, but you will need a mediator if the counterparty agent only supports HTTP transport.

### Receive an invitation

Create a connection by receiving a connection invitation or an out-of-band invitation.
```swift
let (oobRecord, connection) = try await agent.oob.receiveInvitationFromUrl(url)
```

You will generally get the invitation URL by QR code scanning.
Once the connection is created, it is stored in the wallet and your counterparty agent can send you a credential or a proof request using the connection at any time. The connection record contains the keys used to encrypt and decrypt messages exchanged through the connection.

### Receive credentials or proof requests

Implement `AgentDelegate` to receive events from the agent and use `agent.credentials` / `agent.credentialsV2` (credentials) and `agent.proofs` / `agent.proofCommandV2` (proofs) commands to handle the requests.

```swift
class MyAgentDelegate: AgentDelegate {
    func onCredentialStateV2Changed(credentialRecord: CredentialExchangeRecord) {
        if credentialRecord.state == .OfferReceived {
            processCredentialOfferV2(credentialRecord)
        } else if credentialRecord.state == .Done {
            showSimpleAlert(message: "Credential received")
        }
    }

    func onProofStateChangedV2(proofRecord: ProofExchangeRecord) {
        if proofRecord.state == .RequestReceived {
            processProofRequestV2(proofRecord)
        } else if proofRecord.state == .Done {
            showSimpleAlert(message: "Proof done")
        }
    }

    func processCredentialOfferV2(_ credentialRecord: CredentialExchangeRecord) {
        Task {
            do {
                _ = try await agent.credentialsV2.acceptOffer(
                    options: AcceptCredentialOfferOptionsV2(
                        credentialExchangeRecord: credentialRecord,
                        autoAcceptCredential: .always
                    )
                )
            } catch {
                showSimpleAlert(message: "Failed to receive credential")
                print(error)
            }
        }
    }

    func processProofRequestV2(_ proofRecord: ProofExchangeRecord) {
        Task {
            do {
                _ = try await agent.proofCommandV2.acceptRequest(
                    proofRecordId: proofRecord.id,
                    chosenCredentialId: nil
                )
            } catch {
                showSimpleAlert(message: "Failed to present proof")
                print(error)
            }
        }
    }
}
```

If you set `autoAcceptCredential` and `autoAcceptProof` to `.always` in the config, this is done automatically and you don't need to implement a delegate.

Another way to handle those requests is to implement your own `MessageHandler` class and register it to the agent.
```swift
let messageHandler = MyOfferCredentialHandler()
agent.dispatcher.registerHandler(handler: messageHandler)
```

#### W3C Verifiable Credentials

Beside AnonCreds, the framework also stores and serves W3C Verifiable Credentials (JSON-LD) through `agent.w3cCredentialService` / `agent.w3cJsonLdCredentialService` and the `W3cCredential` model, backed by `agent.w3cCredentialRepository`.

#### Other capabilities

- `agent.historyRepository` / `HistoryService` — local history of exchanges.
- `agent.verifierRepository` / proof V2 verifier APIs (`agent.anoncredsVerifierService`).
- `agent.wallet` — wallet access; `agent.reset()` wipes local data and connections.
- Connectionless (QR-based) proof exchange for both holder and verifier is available through the sample app's `RequestProofViewVerifierConnectionLess` and `VerifierProofView`.

## Sample App

`Sample` directory contains an iOS sample app that demonstrates how to use Aries Framework Swift. The app receives a connection invitation from a QR code or from a URL input and handles credential offers and proof requests.

The agent is created in the `WalletOpener.swift` file and you can set a mediator connection invitation url there, if you want.

There are two genesis files in the `resources` directory.
- `bcovrin-genesis.txn` is for the [GreenLight Dev Ledger](http://dev.greenlight.bcovrin.vonx.io/)
- `local-genesis.txn` is for the local indy-pool.

## Using the Besu ledger

When you need to use the **Besu ledger** (the Ethereum-based ledger backed by the
[`indy-besu`](https://github.com/hyperledger-indy/indy-besu) project), the framework relies
on the Swift bindings generated by the `uniffi` tooling of `indy-besu`. These bindings must
be built locally and placed inside the `packages` directory of this repository before the
project compiles.

### 1. Build the `uniffi` bindings from `indy-besu`

Clone or open the [`hyperledger-indy/indy-besu`](https://github.com/hyperledger-indy/indy-besu)
repository and run the `vdr/uniffi` tooling to produce the native (FFI) library and the
autogenerated Swift wrapper:

```sh
# from the root of the indy-besu repository
cargo build --release -p indy-besu-vdr
```

The `uniffi` step generates an xcframework bundle (for iOS, macOS and the simulator) that
contains the compiled `indy_besu_vdrFFI` binary, used to talk to the Besu ledger.

### 2. Place the compiled artifacts under `packages`

Copy the generated Swift source and the xcframework into this repository's local package
folder so the Swift Package Manager can resolve them:

```
packages/indy-besu/
├── Package.swift
├── Sources/indy_besu_uniffi/        # generated Swift bindings (indy_besu_vdr.swift)
└── Frameworks/
    ├── ios/indy_besu_vdrFFI.framework
    ├── sim/indy_besu_vdrFFI.framework
    ├── macos/indy_besu_vdrFFI.framework
    └── ...
```

The local `package` dependency is referenced from the root `Package.swift` as
`.package(path: "./packages/indy-besu")`, and the app/target consumes the `IndyBesu` product.

### 3. Build the framework

The binary target in `packages/indy-besu/Package.swift` points to an `.xcframework`; make
sure that xcframework is produced (e.g. by assembling the per-platform `.framework`
slices with `xcodebuild -create-xcframework`) and is present at
`packages/indy-besu/Frameworks/indy_besu_vdrFFI.xcframework`, otherwise SwiftPM will fail to
resolve the package.

> **Note:** The Besu native artifacts are intentionally **not** committed to this repository
> (they are ignored via `packages/.gitignore`). Each developer must build and add them
> locally, exactly as described above, for the build to succeed.

## Contributing

We welcome contributions to Aries Framework Swift. Please see our [Developer Guide](DEVELOP.md) for more information.

## License

Aries Framework Swift is licensed under the [Apache License 2.0](LICENSE).
