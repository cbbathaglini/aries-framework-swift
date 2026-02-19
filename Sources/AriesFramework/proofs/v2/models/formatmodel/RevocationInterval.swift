
import Foundation

public struct RevocationInterval: Codable {
    let from: Int?
    let to: Int?

    static func assertBestPractice(
        _ revocationInterval: AnonCredsNonRevokedInterval
    ) throws -> BestPracticeNonRevokedInterval {
        guard let to = revocationInterval.to else {
            throw CredoError("Presentation requests proof of non-revocation with no 'to' value specified.")
        }

//        if let from = revocationInterval.from, from != to {
//            throw CredoError("""
//            Presentation requests proof of non-revocation with an interval from: '\(from)' \
//            that does not match the interval to: '\(to)', as specified in Aries RFC 0441.
//            """)
//        }

        return BestPracticeNonRevokedInterval(
            from: revocationInterval.from,
            to: to
        )
    }
}

