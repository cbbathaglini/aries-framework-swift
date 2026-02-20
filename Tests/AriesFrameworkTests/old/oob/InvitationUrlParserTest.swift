
import XCTest
@testable import AriesFramework
import Criollo

class InvitationUrlParserTest: XCTestCase {
    let oobUrl = "http://example.com/ssi?oob=eyJAdHlwZSI6Imh0dHBzOi8vZGlkY29tbS5vcmcvb3V0LW9mLWJhbmQvMS4xL2ludml0YXRpb24iLCJAaWQiOiI2OTIxMmEzYS1kMDY4LTRmOWQtYTJkZC00NzQxYmNhODlhZjMiLCJsYWJlbCI6IkZhYmVyIENvbGxlZ2UiLCJnb2FsX2NvZGUiOiJpc3N1ZS12YyIsImdvYWwiOiJUbyBpc3N1ZSBhIEZhYmVyIENvbGxlZ2UgR3JhZHVhdGUgY3JlZGVudGlhbCIsImhhbmRzaGFrZV9wcm90b2NvbHMiOlsiaHR0cHM6Ly9kaWRjb21tLm9yZy9kaWRleGNoYW5nZS8xLjAiLCJodHRwczovL2RpZGNvbW0ub3JnL2Nvbm5lY3Rpb25zLzEuMCJdLCJzZXJ2aWNlcyI6WyJkaWQ6c292OkxqZ3BTVDJyanNveFllZ1FEUm03RUwiXX0K"
    let invitationUrl = "https://example.com?c_i=eyJAdHlwZSI6ICJkaWQ6c292OkJ6Q2JzTlloTXJqSGlxWkRUVUFTSGc7c3BlYy9jb25uZWN0aW9ucy8xLjAvaW52aXRhdGlvbiIsICJAaWQiOiAiZmM3ODFlMDItMjA1YS00NGUzLWE5ZTQtYjU1Y2U0OTE5YmVmIiwgInNlcnZpY2VFbmRwb2ludCI6ICJodHRwczovL2RpZGNvbW0uZmFiZXIuYWdlbnQuYW5pbW8uaWQiLCAibGFiZWwiOiAiQW5pbW8gRmFiZXIgQWdlbnQiLCAicmVjaXBpZW50S2V5cyI6IFsiR0hGczFQdFRabjdmYU5LRGVnMUFzU3B6QVAyQmpVckVjZlR2bjc3SnBRTUQiXX0="

    func testPlainUrl_decodesGeneratedOob() throws {
    
        let oob = OutOfBandInvitation(
            id: "test-id",
            label: "Faber College",
            goalCode: "issue-vc",
            goal: "To issue a credential",
            handshakeProtocols: [.DidExchange11],
            requests: [],
            services: [.did("did:sov:LjgpST2rjsoxYegQDRm7EL")]
        )

        let url = try oob.toUrl(domain: "http://example.com/ssi")

        let parsed = try OutOfBandInvitation.fromUrl(url)
        XCTAssertEqual(parsed.label, "Faber College")
        XCTAssertFalse(parsed.services.isEmpty)
    }
    
    func testShortUrl() async throws {
        let server = CRHTTPServer()

        server.get("/invitation") { (req, res, next) in
            Task {
                do {
                    let invitation = try ConnectionInvitationMessage.fromUrl(self.invitationUrl)
                    let message = try JSONEncoder().encode(invitation)
                    res.setValue("application/json", forHTTPHeaderField: "Content-type")
                    res.send(String(data: message, encoding: .utf8)!)
                } catch {
                    res.setStatusCode(500, description: nil)
                    res.send("error: \(error)")
                }
            }
        }

        server.get("/oob") { (req, res, next) in
            Task {
                do {
                
                    let oob = OutOfBandInvitation(
                        id: "69212a3a-d068-4f9d-a2dd-4741bca89af3",
                        label: "Faber College",
                        goalCode: "issue-vc",
                        goal: "To issue a Faber College Graduate credential",
                        accept: nil,
                        handshakeProtocols: [
                            .DidExchange11
                        ],
                        requests: [],
                        services: [
                            .did("did:sov:LjgpST2rjsoxYegQDRm7EL")
                        ],
                        imageUrl: nil
                    )

                    let message = try JSONEncoder().encode(oob)
                    res.setValue("application/json", forHTTPHeaderField: "Content-type")
                    res.send(String(data: message, encoding: .utf8)!)

                } catch {
                    res.setStatusCode(500, description: nil)
                    res.send("error: \(error)")
                }
            }
        }

        var serverError: NSError?
        server.startListening(&serverError, portNumber: 8080)
        XCTAssertNil(serverError)

        defer {
            server.stopListening()
        }

        var (outOfBandInvitation, invitation) = try await InvitationUrlParser.parseUrl("http://localhost:8080/oob")
        XCTAssertNotNil(outOfBandInvitation)
        XCTAssertNil(invitation)
        XCTAssertEqual(outOfBandInvitation?.label, "Faber College")

        (outOfBandInvitation, invitation) = try await InvitationUrlParser.parseUrl("http://localhost:8080/invitation")
        XCTAssertNil(outOfBandInvitation)
        XCTAssertNotNil(invitation)

        await XCTAssertThrowsErrorAsync {
            _ = try await InvitationUrlParser.parseUrl("http://localhost:8080/invalid")
        }
    }
    
    private func XCTAssertThrowsErrorAsync(
        _ expression: @escaping () async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            try await expression()
            XCTFail("Expected error to be thrown", file: file, line: line)
        } catch {
            // ok
        }
    }
}
