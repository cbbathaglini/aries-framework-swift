
import Foundation
import AnyCodable

public struct CredentialRecordBinding: Codable {
    public let credentialRecordType: String
    public let credentialRecordId: String
    
    public func toMap() -> [String: Any?] {
        return [
            "credentialRecordType": self.credentialRecordType,
            "credentialRecordId": self.credentialRecordId
        ]
    }
}

public class CredentialExchangeRecord: BaseRecord {
    public var id: String = RecordUtils.generateId()
    public var createdAt: Date = Date()
    public var updatedAt: Date?
    public var tags: Tags?
    public var metadata: [String:AnyCodable] = [:]
    
    public var connectionId: String?
    public var threadId: String
    public var parentThreadId: String?
    public var state: CredentialState
    public var autoAcceptCredential: AutoAcceptCredential?
    public var errorMessage: String?
    public var protocolVersion: String
    public var credentials: [CredentialRecordBinding] = []
    public var credentialAttributes: [CredentialPreviewAttribute]?
    public var indyRequestMetadata: String?
    public var credentialDefinitionId: String?
    public var role: CredentialRole?
    public var revocationNotification: RevocationNotification?
    
    public var schemaId: String?
    public var schemaName: String?
    public var schemaVersion: String?
    public var schemaIssuerId: String?
    
    public var credRevId: String?
    public var revRegId: String?
    public var revRegDefId: String?
    public var w3cCredentialId: String?
    
    public var formats: [Format]?
    
    public static let type = "CredentialExchangeRecord"
    
    init(
        tags: Tags? = nil,
        connectionId: String?,
        threadId: String,
        parentThreadId: String? = nil,
        state: CredentialState,
        autoAcceptCredential: AutoAcceptCredential? = nil,
        errorMessage: String? = nil,
        protocolVersion: String,
        credentials: [CredentialRecordBinding]? = nil,
        credentialAttributes: [CredentialPreviewAttribute]? = nil,
        role: CredentialRole? = nil,
        schemaId: String? = nil,
        schemaName: String? = nil,
        schemaVersion: String? = nil,
        schemaIssuerId: String? = nil,
        credRevId: String? = nil,
        revRegId: String? = nil,
        revRegDefId: String? = nil,
        formats:[Format]? = nil,
        metadata:[String:AnyCodable] = [:]
        ) {

        self.id = UUID().uuidString
        self.createdAt = Date()
        self.tags = tags
        self.connectionId = connectionId
        self.threadId = threadId
        self.parentThreadId = parentThreadId
        self.state = state
        self.autoAcceptCredential = autoAcceptCredential
        self.errorMessage = errorMessage
        self.protocolVersion = protocolVersion
        self.credentials = credentials ?? []
        self.credentialAttributes = credentialAttributes
        self.role = role
        self.schemaId = schemaId
        self.schemaName = schemaName
        self.schemaVersion = schemaVersion
        self.schemaIssuerId = schemaIssuerId
        self.credRevId = credRevId
        self.revRegId = revRegId
        self.revRegDefId = revRegDefId
        self.formats = formats
        self.metadata = metadata
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        self.tags = try container.decodeIfPresent([String: String].self, forKey: .tags)
        self.metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata) ?? [:]

        self.connectionId = try container.decodeIfPresent(String.self, forKey: .connectionId)
        self.threadId = try container.decode(String.self, forKey: .threadId)
        self.parentThreadId = try container.decodeIfPresent(String.self, forKey: .parentThreadId)
        self.state = try container.decode(CredentialState.self, forKey: .state)
        self.autoAcceptCredential = try container.decodeIfPresent(AutoAcceptCredential.self, forKey: .autoAcceptCredential)
        self.errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        self.protocolVersion = try container.decode(String.self, forKey: .protocolVersion)
        self.credentials = try container.decodeIfPresent([CredentialRecordBinding].self, forKey: .credentials) ?? []
        self.credentialAttributes = try container.decodeIfPresent([CredentialPreviewAttribute].self, forKey: .credentialAttributes)
        self.indyRequestMetadata = try container.decodeIfPresent(String.self, forKey: .indyRequestMetadata)
        self.credentialDefinitionId = try container.decodeIfPresent(String.self, forKey: .credentialDefinitionId)
        self.role = try container.decodeIfPresent(CredentialRole.self, forKey: .role)
        self.revocationNotification = try container.decodeIfPresent(RevocationNotification.self, forKey: .revocationNotification)

        self.schemaId = try container.decodeIfPresent(String.self, forKey: .schemaId)
        self.schemaName = try container.decodeIfPresent(String.self, forKey: .schemaName)
        self.schemaVersion = try container.decodeIfPresent(String.self, forKey: .schemaVersion)
        self.schemaIssuerId = try container.decodeIfPresent(String.self, forKey: .schemaIssuerId)

        self.credRevId = try container.decodeIfPresent(String.self, forKey: .credRevId)
        self.revRegId = try container.decodeIfPresent(String.self, forKey: .revRegId)
        self.revRegDefId = try container.decodeIfPresent(String.self, forKey: .revRegDefId)
        self.w3cCredentialId = try container.decodeIfPresent(String.self, forKey: .w3cCredentialId)

        self.formats = try container.decodeIfPresent([Format].self, forKey: .formats)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encode(metadata, forKey: .metadata)

        try container.encodeIfPresent(connectionId, forKey: .connectionId)
        try container.encode(threadId, forKey: .threadId)
        try container.encodeIfPresent(parentThreadId, forKey: .parentThreadId)
        try container.encode(state, forKey: .state)
        try container.encodeIfPresent(autoAcceptCredential, forKey: .autoAcceptCredential)
        try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
        try container.encode(protocolVersion, forKey: .protocolVersion)
        try container.encode(credentials, forKey: .credentials)
        try container.encodeIfPresent(credentialAttributes, forKey: .credentialAttributes)
        try container.encodeIfPresent(indyRequestMetadata, forKey: .indyRequestMetadata)
        try container.encodeIfPresent(credentialDefinitionId, forKey: .credentialDefinitionId)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encodeIfPresent(revocationNotification, forKey: .revocationNotification)

        try container.encodeIfPresent(schemaId, forKey: .schemaId)
        try container.encodeIfPresent(schemaName, forKey: .schemaName)
        try container.encodeIfPresent(schemaVersion, forKey: .schemaVersion)
        try container.encodeIfPresent(schemaIssuerId, forKey: .schemaIssuerId)

        try container.encodeIfPresent(credRevId, forKey: .credRevId)
        try container.encodeIfPresent(revRegId, forKey: .revRegId)
        try container.encodeIfPresent(revRegDefId, forKey: .revRegDefId)
        try container.encodeIfPresent(formats, forKey: .formats)
        try container.encodeIfPresent(w3cCredentialId, forKey: .w3cCredentialId)
    }
}

extension CredentialExchangeRecord: Codable {
    enum CodingKeys: String, CodingKey {
        case id, createdAt, updatedAt, tags, metadata
        case connectionId, threadId, parentThreadId, state, autoAcceptCredential, errorMessage, protocolVersion, credentials, credentialAttributes, indyRequestMetadata, credentialDefinitionId, role, revocationNotification,
             schemaId, schemaName, schemaVersion, schemaIssuerId, credRevId, revRegId, revRegDefId, formats, w3cCredentialId
    }


    
    func setState(_ newState: CredentialState) {
        self.state = newState
    }

    func updateSchema(schemaId: String, schema: AnonCredsSchema) {
        self.schemaId = schemaId
        self.schemaName = schema.name
        self.schemaIssuerId = schema.issuerId
        self.schemaVersion = schema.version
    }

    func updateRevocationInfos(credRevId: String?=nil, revRegId: String?=nil, revRegDefId: String?) {
        self.credRevId = credRevId
        self.revRegId = revRegId
        self.revRegDefId = revRegDefId
    }
    
    public func addMetadata(key: String, value: AnyCodable) {
        metadata[key] = value
    }
    
    public func setCredRevId(_ credRevId: String?) {
        self.credRevId = credRevId
    }
    
    public func setRevRegId(_ revRegId: String?) {
        self.revRegId = revRegId
    }

    public func setRevRegDefId(_ revRegDefId: String?) {
        self.revRegDefId = revRegDefId
    }

    public func setCredentialDefinitionId(_ credentialDefinitionId: String?) {
        self.credentialDefinitionId = credentialDefinitionId
    }
    
    public func setTags(_ tags: Tags) {
        self.tags = tags
    }

    public func getTags() -> Tags {
        var tags = self.tags ?? [:]

        let credentialIds = self.credentials.map { $0.credentialRecordId }

        tags["threadId"] = self.threadId
        tags["connectionId"] = connectionId
        tags["state"] = self.state.rawValue
        tags["credentialIds"] = credentialIds.joined(separator: ",")
        tags["role"] = self.role?.rawValue

        return tags
    }

    public func getCredentialInfo() -> IndyCredentialView? {
        guard let credentialAttributes = self.credentialAttributes else {
            return nil
        }

        let claims = credentialAttributes.reduce(into: [String: String]()) { (accumulator, current) in
            accumulator[current.name] = current.value
        }

        return IndyCredentialView(claims: claims)
    }

    public func assertProtocolVersion(_ version: String) throws {
        if self.protocolVersion != version {
            throw AriesFrameworkError.frameworkError(
                "Credential record has invalid protocol version \(self.protocolVersion). Expected version \(version)"
            )
        }
    }

    public func assertState(_ expectedStates: CredentialState...) throws {
        if !expectedStates.contains(self.state) {
            throw AriesFrameworkError.frameworkError(
                "Credential record is in invalid state \(self.state). Valid states are: \(expectedStates)"
            )
        }
    }

    public func assertConnection(_ currentConnectionId: String) throws {
        if self.connectionId != currentConnectionId {
            throw AriesFrameworkError.frameworkError(
                "Credential record is associated with connection '\(self.connectionId)'. Current connection is '\(currentConnectionId)'"
            )
        }
    }
    
    public func toMap() -> [String: Any?] {
        // @TODO completar
        return [
            "id": self.id,
            "createdAt" : String.fromDate(self.createdAt),
            "updatedAt" : String.fromDate(self.updatedAt),
            "tags": self.tags,
            "metadata": self.metadata,
            
            "connectionId": self.connectionId,
            "threadId": self.threadId,
            "parentThreadId": self.parentThreadId,
            "state" : self.state.description,
            "autoAcceptCredential": self.autoAcceptCredential?.description ?? nil,
            "errorMessage": self.errorMessage,
            "protocolVersion": self.protocolVersion,
//            "credentials": self.credentials.toMap(),
            "credentialAttributes": self.credentialAttributes,
            "indyRequestMetadata": self.indyRequestMetadata,
            "credentialDefinitionId": self.credentialDefinitionId,
            "role" : self.role?.description,
            "revocationNotification": self.revocationNotification?.toMap() ?? nil,
            
            "schemaId": self.schemaId,
            "schemaName": self.schemaName,
            "schemaVersion": self.schemaVersion,
            "schemaIssuerId": self.schemaIssuerId,
            "credRevId": self.credRevId,
            "revRegId": self.revRegId,
            "revRegDefId": self.revRegDefId,
            "w3cCredentialId": self.w3cCredentialId,
            //"formats": obj.formats,
            "type": "self"
        ]
    }
}


class CredentialExchangeRecordBuilder {
    
    private var id: String = RecordUtils.generateId()
    private var createdAt: Date = Date()
    private var updatedAt: Date?
    private var tags: Tags? = nil
    private var connectionId: String? = nil
    private var threadId: String = UUID().uuidString
    private var parentThreadId: String? = nil
    private var state: CredentialState = CredentialState.Default
    private var autoAcceptCredential: AutoAcceptCredential? = nil
    private var errorMessage: String? = nil
    private var protocolVersion: String = "v1"
    private var credentials: [CredentialRecordBinding]? = nil
    private var credentialAttributes: [CredentialPreviewAttribute]? = nil
    private var role: CredentialRole? = nil
    private var schemaId: String? = nil
    private var schemaName: String? = nil
    private var schemaVersion: String? = nil
    private var schemaIssuerId: String? = nil
    private var credRevId: String? = nil
    private var revRegId: String? = nil
    private var revRegDefId: String? = nil
    private var formats: [Format]? = nil
    private var metadata: [String:AnyCodable] = [:]
    private var revocationNotification: RevocationNotification? = nil
    private var credentialDefinitionId: String? = nil
    private var w3cCredentialId: String? = nil

    func setId(_ id: String) -> Self {
        self.id = id
        return self
    }
    
    func setCreatedAt(_ createdAt: Date) -> Self {
        self.createdAt = createdAt
        return self
    }
    
    func setUpdatedAt(_ updatedAt: Date?) -> Self {
        self.updatedAt = updatedAt
        return self
    }
    
    func setTags(_ tags: Tags?) -> Self {
        self.tags = tags
        return self
    }

    func setRevocationNotification(_ revocationNotification: RevocationNotification?) -> Self {
        self.revocationNotification = revocationNotification
        return self
    }

    func setCredentialDefinitionId(_ credentialDefinitionId: String?) -> Self {
        self.credentialDefinitionId = credentialDefinitionId
        return self
    }

    
    func setConnectionId(_ id: String?) -> Self {
        self.connectionId = id
        return self
    }

    func setThreadId(_ id: String) -> Self {
        self.threadId = id
        return self
    }

    func setParentThreadId(_ id: String?) -> Self {
        self.parentThreadId = id
        return self
    }

    func setState(_ state: CredentialState) -> Self {
        self.state = state
        return self
    }

    func setAutoAcceptCredential(_ value: AutoAcceptCredential?) -> Self {
        self.autoAcceptCredential = value
        return self
    }

    func setErrorMessage(_ msg: String?) -> Self {
        self.errorMessage = msg
        return self
    }

    func setProtocolVersion(_ version: String) -> Self {
        self.protocolVersion = version
        return self
    }

    func setCredentials(_ list: [CredentialRecordBinding]?) -> Self {
        self.credentials = list
        return self
    }

    func setCredentialAttributes(_ attrs: [CredentialPreviewAttribute]?) -> Self {
        self.credentialAttributes = attrs
        return self
    }

    func setRole(_ role: CredentialRole?) -> Self {
        self.role = role
        return self
    }

    func setSchemaId(_ id: String?) -> Self {
        self.schemaId = id
        return self
    }

    func setSchemaName(_ name: String?) -> Self {
        self.schemaName = name
        return self
    }

    func setSchemaVersion(_ version: String?) -> Self {
        self.schemaVersion = version
        return self
    }

    func setSchemaIssuerId(_ id: String?) -> Self {
        self.schemaIssuerId = id
        return self
    }

    
    func setCredRevId(_ id: String?) -> Self {
        self.credRevId = id
        return self
    }
    
    func setRevRegId(_ id: String?) -> Self {
        self.revRegId = id
        return self
    }

    func setRevRegDefId(_ id: String?) -> Self {
        self.revRegDefId = id
        return self
    }

    func setFormats(_ formats: [Format]?) -> Self {
        self.formats = formats
        return self
    }
    
    func setMetadata(_ metadata: [String:AnyCodable]) -> Self {
        self.metadata = metadata
        return self
    }

    func build() -> CredentialExchangeRecord {
        return CredentialExchangeRecord(
            tags: tags,
            connectionId: connectionId,
            threadId: threadId,
            parentThreadId: parentThreadId,
            state: state,
            autoAcceptCredential: autoAcceptCredential,
            errorMessage: errorMessage,
            protocolVersion: protocolVersion,
            credentials: credentials,
            credentialAttributes: credentialAttributes,
            role: role,
            schemaId: schemaId,
            schemaName: schemaName,
            schemaVersion: schemaVersion,
            schemaIssuerId: schemaIssuerId,
            credRevId: credRevId,
            revRegId: revRegId,
            revRegDefId: revRegDefId,
            formats: formats,
            metadata: metadata
        )
    }
}

extension CredentialExchangeRecord: CustomStringConvertible {
    public var description: String {
        let tagDescription: String
                if let tags = tags, !tags.isEmpty {
                    tagDescription = tags.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
                } else {
                    tagDescription = "none"
                }
        return """
        CredentialExchangeRecord(
            id: \(id),
            createdAt: \(createdAt),
            updatedAt: \(String(describing: updatedAt)),
            threadId: \(threadId),
            connectionId: \(String(describing: connectionId)),
            state: \(state),
            protocolVersion: \(protocolVersion),
            role: \(String(describing: role)),
            schemaId: \(String(describing: schemaId)),
            credentialDefinitionId: \(String(describing: credentialDefinitionId)),
            credRevId: \(String(describing: credRevId)),
            revRegId: \(String(describing: revRegId)),
            revRegDefId: \(String(describing: revRegDefId)),
            credentials: \(credentials.map { "\($0.credentialRecordType): \($0.credentialRecordId)" }.joined(separator: ", ")),
            credentialAttributes: \(String(describing: credentialAttributes)),
            formats: \(String(describing: formats)),
            metadata: \(metadata),
            tags: [\(tagDescription)]
        )
        """
    }
}

