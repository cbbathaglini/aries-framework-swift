
import Foundation


public struct AcceptOfferOptions {
    public var credentialRecordId: String
    public var holderDid: String?
    public var autoAcceptCredential: AutoAcceptCredential?
    public var comment: String?

    public init(credentialRecordId: String, holderDid: String? = nil, autoAcceptCredential: AutoAcceptCredential? = nil, comment: String? = nil) {
        self.credentialRecordId = credentialRecordId
        self.holderDid = holderDid
        self.autoAcceptCredential = autoAcceptCredential
        self.comment = comment
    }
}

public struct AcceptRequestOptions {
    public var credentialRecordId: String
    public var autoAcceptCredential: AutoAcceptCredential?
    public var comment: String?

    public init(credentialRecordId: String, autoAcceptCredential: AutoAcceptCredential? = nil, comment: String? = nil) {
        self.credentialRecordId = credentialRecordId
        self.autoAcceptCredential = autoAcceptCredential
        self.comment = comment
    }
}

public struct AcceptCredentialOptions {
    public var credentialRecordId: String

    public init(credentialRecordId: String) {
        self.credentialRecordId = credentialRecordId
    }
}
