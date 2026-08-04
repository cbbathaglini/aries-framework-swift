import Foundation
import IndyVdr
import os
import Anoncreds
import indy_besu_vdr_uniffi

public class BesuLedgerService: LedgerService {
    let agent: Agent
    let logger = Logger(subsystem: "AriesFramework", category: "BesuLedgerService")
    
    private let DAY_MS: Int64 = 24 * 60 * 60 * 1000
    
    private var pool: Pool?
    private var ledgerClient: LedgerClient? = nil
    private var ledgerRouter: LedgerRouter? = nil
    private let issuer = Issuer()
    
    
    private lazy var cacheCfg: LedgerCacheConfig = {
        LedgerCacheConfig.loadFromInfoPlist(bundle: .main)
    }()
    
    private func credDefTtlDaysFor(_ credDefId: String) -> Int64 {
        cacheCfg.credDefTtlDaysById[credDefId] ?? cacheCfg.credDefDefaultDays
    }
    
    private var credDefJsonCachesByDays: [Int64: DiskOnlyAsyncTtlCache<String, String>] = [:]
    private var credDefVdrCachesByDays: [Int64: DiskOnlyAsyncTtlCache<String, CredDefVdrCacheDto>] = [:]
    
    private lazy var schemaJsonCache = DiskOnlyAsyncTtlCache<String, String>(
        cacheName: LedgerCacheDefaults.SCHEMA_JSON,
        ttlMillis: cacheCfg.schemaTtlDays * DAY_MS,
        keyToString: { $0 }
    )

    private lazy var revRegDefCache = DiskOnlyAsyncTtlCache<String, RevRegDefDto>(
        cacheName: LedgerCacheDefaults.REG_DEF,
        ttlMillis: cacheCfg.revRegTtlDays * DAY_MS,
        keyToString: { $0 }
    )

    private lazy var tailsPathCache = DiskOnlyAsyncTtlCache<String, String>(
        cacheName: LedgerCacheDefaults.TAILS_PATH,
        ttlMillis: cacheCfg.tailsTtlDays * DAY_MS,
        keyToString: { $0 }
    )
    
    private var activeLedgerMetadata: [String: Any] = [:]
    
    private var configFile: String {
        let raw = agent.agentConfig.besuLedgerConfig?.configFile.trimmingCharacters(in: .whitespacesAndNewlines)
        return (raw?.isEmpty == false) ? raw! : "besu_config"
    }
    
    private var isMultiLedger: Bool {
        agent.agentConfig.besuLedgerConfig?.multiledger ?? false
    }
    
    init(agent: Agent) {
        self.agent = agent
    }

    
    func loadLedgerConfig() throws -> [String: Any] {
        let name = (configFile as NSString).deletingPathExtension

        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw NSError(domain: "LedgerBesuService", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Config file not found: \(name).json"])
        }

        let data = try Data(contentsOf: url)
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw NSError(domain: "LedgerBesuService", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
        }
        return json
    }

    // MARK: - Load Contract Configs (adaptado)
    
    func loadContractConfigsForNetwork(networkJson: [String: Any]) -> [ContractConfig] {
        var configs: [ContractConfig] = []
        
        guard let contracts = networkJson["contracts"] as? [String: Any] else { return [] }
        
        for (_, value) in contracts {
            guard let obj = value as? [String: Any],
                  let address = obj["address"] as? String,
                  let specPath = obj["specPath"] as? String else {
                continue
            }
            
            do {
                let config = try ContractConfigBesu.loadFromFile(address: address, specPath: specPath)
                configs.append(config)
            } catch {
                logger.error("❌ Failed to load contract spec \(specPath): \(error.localizedDescription)")
            }
        }
        return configs
    }

    // MARK: - Initialize
    
    public func initialize() async throws {
        logDebug("Initializing Pool")
        if pool != nil {
            logger.warning("Pool already initialized.")
            try await close()
        }
    
        
        let configJson = try loadLedgerConfig()
        guard let networks = configJson["networks"] as? [[String: Any]], !networks.isEmpty else {
            throw NSError(domain: "LedgerBesuService", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Missing 'networks' array"])
        }
        
        var clients: [LedgerConfiguration] = []
        let targetNetworks = isMultiLedger ? networks : [networks.first!]
        logDebug("Loading \(self.isMultiLedger ? "multiple" : "single") ledger configuration(s)...")
        
        for network in targetNetworks {
            let networkName = network["networkName"] as? String ?? "default"
            guard let chainId = (network["chainId"] as? NSNumber)?.uint64Value,
                  let nodeAddress = network["nodeAddress"] as? String else {
                logger.warning("Skipping invalid network configuration for \(networkName)")
                continue
            }
            
            let contractConfigs = loadContractConfigsForNetwork(networkJson: network)
            logDebug("Loaded \(contractConfigs.count) contracts for \(networkName)")
            
            let ledgerConfig = LedgerConfiguration(
                chainId: chainId,
                nodeAddress: nodeAddress,
                contractConfigs: contractConfigs,
                network: networkName,
                quorumConfig: nil
            )
            
            clients.append(ledgerConfig)
        }
        
        if clients.isEmpty {
            throw NSError(domain: "LedgerBesuService", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "No valid network configurations found"])
        }
        
        if isMultiLedger {
            ledgerRouter = try LedgerRouter(configs: clients)
            logDebug("LedgerRouter initialized with \(clients.count) networks.")
        } else {
            let first = clients.first!
            ledgerClient = try LedgerClient(
                chainId: first.chainId,
                nodeAddress: first.nodeAddress,
                contractConfigs: first.contractConfigs,
                network: first.network,
                quorumConfig: nil
            )
            logDebug("LedgerClient initialized in single-ledger mode (\(first.network ?? "default")).")
            
        }
        
    }
    
    
    public func getTailsPath() async throws -> String {
        let start = Date()

        if let cached = await tailsPathCache.getIfFresh(LedgerCacheDefaults.TAILS_PATH) {
            logDebug("[CACHE HIT] getTailsPath took \(Int(Date().timeIntervalSince(start)*1000))ms")
            return cached
        }

        let path = try await tailsPathCache.getOrLoad(LedgerCacheDefaults.TAILS_PATH) {
            let fm = FileManager.default
            let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
            let tails = docs.appendingPathComponent("tails", isDirectory: true)
            try? fm.createDirectory(at: tails, withIntermediateDirectories: true)
            return tails.path
        }

        logDebug("[CACHE STORE] getTailsPath took \(Int(Date().timeIntervalSince(start)*1000))ms")
        return path
    }
    
    public func getLedgerClient(network: String? = nil) throws -> LedgerClient {
        if isMultiLedger {
            guard let network = network else {
                throw NSError(
                    domain: "LedgerBesuService",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Network name required for multiledger mode"]
                )
            }

            if let ledger = try ledgerRouter?.getLedgerForIdentifier(identifier: network) {
                activeLedgerMetadata["currentNetwork"] = network
                logDebug("🔄 Switched to ledger network: \(network)")
                return ledger
            } else {
                throw NSError(
                    domain: "LedgerBesuService",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Ledger not found for network \(network)"]
                )
            }
        } else {
            guard let ledger = ledgerClient else {
                throw NSError(
                    domain: "LedgerBesuService",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Ledger client not initialized"]
                )
            }
            return ledger
        }
    }
    
    public func close() async throws {
        if pool != nil {
            try await pool!.closePool()
            pool = nil
        }
    }
    
    //cache
    private func credDefJsonCacheFor(_ credDefId: String) -> DiskOnlyAsyncTtlCache<String, String> {
        let days = max(1, credDefTtlDaysFor(credDefId))
        if let existing = credDefJsonCachesByDays[days] { return existing }

        let ttlMillis = days * DAY_MS // Int

        let created = DiskOnlyAsyncTtlCache<String, String>(
            cacheName: "\(LedgerCacheDefaults.CRED_DEF)_\(days)",
            ttlMillis: ttlMillis,
            keyToString: { $0 }
        )
        credDefJsonCachesByDays[days] = created
        return created
    }

    private func credDefVdrCacheFor(_ credDefId: String) -> DiskOnlyAsyncTtlCache<String, CredDefVdrCacheDto> {
        let days = max(1, credDefTtlDaysFor(credDefId))
        if let existing = credDefVdrCachesByDays[days] { return existing }

        let created = DiskOnlyAsyncTtlCache<String, CredDefVdrCacheDto>(
            cacheName: "\(LedgerCacheDefaults.CRED_DEF_VDR)_\(days)",
            ttlMillis: Int64(days) * DAY_MS,
            keyToString: { $0 }
        )
        credDefVdrCachesByDays[days] = created
        return created
    }
    
    public func registerSchema(did: DidInfo, schemaTemplate: SchemaTemplate) async throws -> String {
        throw NSError(domain: "LedgerError", code: 0,
                      userInfo: [NSLocalizedDescriptionKey: "registerSchema not implemented for Besu"])
    }

    public func registerCredentialDefinition(did: DidInfo, credentialDefinitionTemplate: CredentialDefinitionTemplate) async throws -> String {
        throw NSError(domain: "LedgerError", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "registerCredentialDefinition not implemented for Besu"])
    }

    public func registerRevocationRegistryDefinition(did: DidInfo, revRegDefTemplate: RevocationRegistryDefinitionTemplate) async throws -> String {
        throw NSError(domain: "LedgerError", code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "registerRevocationRegistryDefinition not implemented for Besu"])
    }

    public func revokeCredential(did: DidInfo,credDefId: String,revocationIndex: Int) async throws {
        throw NSError(domain: "",code: 0,
            userInfo: [NSLocalizedDescriptionKey: "revokeCredential not implemented for Besu"])
    }
    
    // MARK: - Schema
    public func getSchema(schemaId: String) async throws -> (String, Int) {
        let start = Date()
        let expiresAt = Date().addingTimeInterval(TimeInterval(schemaJsonCache.ttlMillis) / 1000.0)

        if let cached = await schemaJsonCache.getIfFresh(schemaId) {
            logDebug("[DISK CACHE HIT][SCHEMA] \(schemaId) ttl=\(schemaJsonCache.ttlMillis)ms expiresAt=\(expiresAt) took \(Int(Date().timeIntervalSince(start)*1000))ms")
            return (cached, 0)
        }

        logDebug("[DISK CACHE MISS][SCHEMA] \(schemaId) ttl=\(schemaJsonCache.ttlMillis)ms willExpireAt=\(expiresAt) → fetching from ledger")

        let json = try await schemaJsonCache.getOrLoad(schemaId) {
            let client = try self.ledgerClient ?? self.getLedgerClient(network: schemaId)
            let schema = try await resolveSchema(client: client, id: schemaId)

            let schemaMap: [String: Any] = [
                "name": schema.name,
                "version": schema.version,
                "issuerId": schema.issuerId,
                "attrNames": schema.attrNames
            ]

            let data = try JSONSerialization.data(withJSONObject: schemaMap, options: [])
            return String(data: data, encoding: .utf8) ?? "{}"
        }

        logDebug("[DISK CACHE STORE][SCHEMA] \(schemaId) expiresAt=\(expiresAt) took \(Int(Date().timeIntervalSince(start)*1000))ms")
        return (json, 0)
    }

    public func getSchemaObj(schemaId: String) async throws -> AnonCredsSchema {
        let start = Date()
        logDebug("[CALL] getSchemaObj(schemaId=\(schemaId))")

        // ✅ pega json + expiresAt real do disco (hit ou store)
        let hit = try await getRawSchemaJsonWithMeta(schemaId)

        logDebug("[SCHEMA META] schemaId=\(schemaId) expiresAt=\(hit.expiresAtDate)")

        let schemaJson = hit.value
        guard let data = schemaJson.data(using: .utf8),
              let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw NSError(domain: "BesuLedgerService", code: 1001,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid schema JSON for \(schemaId)"])
        }

        guard let issuerId = obj["issuerId"] as? String,
              let name = obj["name"] as? String,
              let version = obj["version"] as? String,
              let attrNames = obj["attrNames"] as? [String]
        else {
            throw NSError(domain: "BesuLedgerService", code: 1002,
                          userInfo: [NSLocalizedDescriptionKey: "Missing fields in schema JSON for \(schemaId)"])
        }

        let result = AnonCredsSchema(
            issuerId: issuerId,
            name: name,
            version: version,
            attrNames: attrNames
        )

        logDebug("[RETURN] getSchemaObj(schemaId=\(schemaId)) took \(Int(Date().timeIntervalSince(start)*1000))ms")
        return result
    }
    

    public func getSchemas(schemaIds: Set<String>) async throws -> [String: AnonCredsSchema] {
        var schemas: [String: AnonCredsSchema] = [:]

        for schemaId in schemaIds {
            let (schemaJson, _) = try await getSchema(schemaId: schemaId)

            guard let data = schemaJson.data(using: .utf8) else { continue }
            let decoded = try JSONDecoder().decode(AnonCredsSchema.self, from: data)

            schemas[schemaId] = decoded
        }

        return schemas
    }
    
    private func getRawSchemaJsonWithMeta(_ schemaId: String) async throws
      -> DiskOnlyAsyncTtlCache<String, String>.CacheHit<String>
    {
        let start = Date()

        if let hit = try await schemaJsonCache.getIfFreshWithMeta(schemaId) {
            logDebug("[DISK CACHE HIT][SCHEMA] schemaId=\(schemaId) expiresAt=\(hit.expiresAtDate) took \(Int(Date().timeIntervalSince(start)*1000))ms")
            return hit
        }

        logDebug("[DISK CACHE MISS][SCHEMA] schemaId=\(schemaId) → fetching from ledger")

        let hit = try await schemaJsonCache.getOrLoadWithMeta(schemaId) {
            logDebug("[LEDGER CALL][SCHEMA] resolveSchema(\(schemaId))")

            let client = try self.ledgerClient ?? self.getLedgerClient(network: schemaId)
            let schema = try await resolveSchema(client: client, id: schemaId)

            let schemaMap: [String: Any] = [
                "name": schema.name,
                "version": schema.version,
                "issuerId": schema.issuerId,
                "attrNames": schema.attrNames
            ]

            let data = try JSONSerialization.data(withJSONObject: schemaMap, options: [])
            return String(data: data, encoding: .utf8) ?? "{}"
        }

        logDebug("[DISK CACHE STORE][SCHEMA] schemaId=\(schemaId) expiresAt=\(hit.expiresAtDate) took \(Int(Date().timeIntervalSince(start)*1000))ms")
        return hit
    }

//    public func getCredentialDefinitionVdr(credentialId id: String) async throws -> indy_besu_vdr_uniffi.CredentialDefinition {
//        let client = try ledgerClient ?? getLedgerClient(network: id)
//        do {
//            return try await resolveCredentialDefinition(client: client, id: id)
//        } catch {
//            logger.error("error cred def >>> \(error.localizedDescription)")
//            throw NSError(domain: "LedgerError", code: 3,
//                          userInfo: [NSLocalizedDescriptionKey: "Credential definition not found"])
//        }
//    }
    
    public func getCredentialDefinitionVdr(credentialId id: String) async throws -> indy_besu_vdr_uniffi.CredentialDefinition {
        let start = Date()
        let ttlDays = credDefTtlDaysFor(id)
        let cache = credDefVdrCacheFor(id)

        if let hit = try await cache.getIfFreshWithMeta(id) {
            logDebug("[DISK CACHE HIT] getCredentialDefinitionVdr(\(id)) ttlDays=\(ttlDays) expiresAt=\(hit.expiresAtDate) took \(Int(Date().timeIntervalSince(start)*1000))ms")
            return hit.value.toVdr()
        }

        logDebug("[DISK CACHE MISS] getCredentialDefinitionVdr(\(id)) ttlDays=\(ttlDays) → fetching from ledger")

        let hit = try await cache.getOrLoadWithMeta(id) {
            let client = try self.ledgerClient ?? self.getLedgerClient(network: id)
            do {
                let vdr = try await resolveCredentialDefinition(client: client, id: id)
                return CredDefVdrCacheDto(from: vdr)
            } catch {
                self.logger.error("error cred def vdr >>> \(error.localizedDescription)")
                throw NSError(domain: "LedgerError", code: 3,
                              userInfo: [NSLocalizedDescriptionKey: "Credential definition not found"])
            }
        }

        logDebug("[DISK CACHE STORE] getCredentialDefinitionVdr(\(id)) ttlDays=\(ttlDays) expiresAt=\(hit.expiresAtDate) took \(Int(Date().timeIntervalSince(start)*1000))ms")
        return hit.value.toVdr()
    }

    public func getCredentialDefinition(id: String) async throws -> String {
        let start = Date()
        let ttlDays = credDefTtlDaysFor(id)
        let cache = credDefJsonCacheFor(id)

        if let hit = try await cache.getIfFreshWithMeta(id) {
            logDebug("[DISK CACHE HIT] getCredentialDefinition(\(id)) ttlDays=\(ttlDays) expiresAt=\(hit.expiresAtDate) took \(Int(Date().timeIntervalSince(start)*1000))ms")
            return hit.value
        }

        logDebug("[DISK CACHE MISS] getCredentialDefinition(\(id)) ttlDays=\(ttlDays) → fetching from ledger")

        let hit = try await cache.getOrLoadWithMeta(id) {
            let client = try self.ledgerClient ?? self.getLedgerClient(network: id)

            let credDef: indy_besu_vdr_uniffi.CredentialDefinition
            do {
                credDef = try await resolveCredentialDefinition(client: client, id: id)
            } catch {
                self.logger.error("error cred def >>> \(error.localizedDescription)")
                throw NSError(domain: "LedgerError", code: 4,
                              userInfo: [NSLocalizedDescriptionKey: "Credential definition not found"])
            }

            guard let valueData = credDef.value.data(using: .utf8),
                  let innerJson = try? JSONSerialization.jsonObject(with: valueData, options: []) else {
                throw NSError(domain: "LedgerError", code: 5,
                              userInfo: [NSLocalizedDescriptionKey: "Failed to parse credential definition value"])
            }

            let payload: [String: Any] = [
                "issuerId": credDef.issuerId,
                "schemaId": credDef.schemaId,
                "type": credDef.credDefType,
                "tag": credDef.tag,
                "value": innerJson
            ]

            let data = try JSONSerialization.data(withJSONObject: payload, options: [])
            return String(data: data, encoding: .utf8) ?? "{}"
        }

        logDebug("[DISK CACHE STORE] getCredentialDefinition(\(id)) ttlDays=\(ttlDays) expiresAt=\(hit.expiresAtDate) took \(Int(Date().timeIntervalSince(start)*1000))ms")
        return hit.value
    }
    
    public func clearLedgerCaches() async {
        await schemaJsonCache.clear()

        for (_, c) in credDefJsonCachesByDays { await c.clear() }
        credDefJsonCachesByDays.removeAll()

        for (_, c) in credDefVdrCachesByDays { await c.clear() }
        credDefVdrCachesByDays.removeAll()

        await revRegDefCache.clear()
        await tailsPathCache.clear()
    }

    public func invalidateCredDef(_ credDefId: String) async {
        let cache = credDefJsonCacheFor(credDefId)
        await cache.invalidate(credDefId)
    }

    public func invalidateCredDefVdr(_ credDefId: String) async {
        let cache = credDefVdrCacheFor(credDefId)
        await cache.invalidate(credDefId)
    }

    // MARK: - Revocation Registry

    public func getRevocationRegistryDefinition(id: String) async throws -> String {
        logDebug("[Besu] Get RevocationRegistryDefinition with id: \(id)")
        let client = try ledgerClient ?? getLedgerClient(network: id)
        let revocationRD = try await resolveRevocationRegistryDefinition(client: client, revRegDefId: id)

        let valueData = revocationRD.value.data(using: .utf8)!
        let parsedValue = try JSONSerialization.jsonObject(with: valueData, options: [])

        let jsonObject: [String: Any] = [
            "issuerId": revocationRD.issuerId,
            "revocDefType": revocationRD.revocDefType,
            "credDefId": revocationRD.credDefId,
            "tag": revocationRD.tag,
            "value": parsedValue
        ]

        let encodedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        return String(data: encodedData, encoding: .utf8)!
    }

    public func getRevocationRegistryDefinitionIndyBesuLib(id: String) async throws -> indy_besu_vdr_uniffi.RevocationRegistryDefinition {
        let start = Date()

        if let cached = await revRegDefCache.getIfFresh(id) {
            logDebug("[CACHE HIT] revRegDef(\(id)) took \(Int(Date().timeIntervalSince(start)*1000))ms")
            return indy_besu_vdr_uniffi.RevocationRegistryDefinition(
                issuerId: cached.issuerId,
                revocDefType: cached.revocDefType,
                credDefId: cached.credDefId,
                tag: cached.tag,
                value: cached.value
            )
        }

        logDebug("[CACHE MISS] revRegDef(\(id)) → fetching from ledger")

        let dto = try await revRegDefCache.getOrLoad(id) {
            let client = try self.ledgerClient ?? self.getLedgerClient(network: id)
            let rr = try await resolveRevocationRegistryDefinition(client: client, revRegDefId: id)

            return RevRegDefDto(
                issuerId: rr.issuerId,
                revocDefType: rr.revocDefType,
                credDefId: rr.credDefId,
                tag: rr.tag,
                value: rr.value
            )
        }

        logDebug("[CACHE STORE] revRegDef(\(id)) took \(Int(Date().timeIntervalSince(start)*1000))ms")

        return indy_besu_vdr_uniffi.RevocationRegistryDefinition(
            issuerId: dto.issuerId,
            revocDefType: dto.revocDefType,
            credDefId: dto.credDefId,
            tag: dto.tag,
            value: dto.value
        )
    }

    public func getRevocationRegistryDelta(id: String, to: Int, from: Int) async throws -> (String, Int) {
        let client = try ledgerClient ?? getLedgerClient(network: id)
        let revocationRD = try await resolveRevocationRegistryDefinition(client: client, revRegDefId: id)
        //logDebug("revocationRD: \(revocationRD)")

        ensureRevRegId(id)

        let statusList = try await resolveRevocationRegistryStatusListFull(client: client, revRegDefId: id, timestamp: UInt64(to))
        let revocationRegistryDelta = RevocationRegistryDelta(
            accum: statusList.currentAccumulator,
            revoked: statusList.revocationList.map { Int($0) }
        )

        return (revocationRegistryDelta.toJsonString(), Int(statusList.timestamp))
    }

    public func getRevocationRegistry(id: String, timestamp: Int) async throws -> (String, Int) {
        let client = try ledgerClient ?? getLedgerClient(network: id)
        let statusList = try await resolveRevocationRegistryStatusList(client: client, revRegDefId: id, timestamp: UInt64(timestamp))
        let revocationStatus = try revocationStatusListFromString(statusListStr: statusList)

        let delta = RevocationRegistryDelta(
            accum: revocationStatus.currentAccumulator,
            revoked: revocationStatus.revocationList.map { Int($0) }
        )
        return (delta.toJsonString(), Int(revocationStatus.timestamp))
    }

    public func getRevocationStatusList(id: String, timestamp: UInt64) async throws -> indy_besu_vdr_uniffi.RevocationStatusList {
        let client = try ledgerClient ?? getLedgerClient(network: id)
        return try await resolveRevocationRegistryStatusListFull(client: client, revRegDefId: id, timestamp: timestamp)
    }
    

    private func ensureRevRegId(_ id: String) {
        guard id.contains("/REV_REG_DEF/") || id.contains("/REV_REG/") else {
            fatalError("Expected REV_REG_DEF or REV_REG id, received: \(id)")
        }
    }

    private func toSecondsULong(_ ts: Int64) -> UInt64 {
        return ts > 10_000_000_000 ? UInt64(ts / 1000) : UInt64(ts)
    }


    class ContractConfigBesu {
        var address: String = ""
        var specPath: String = ""
        var spec: ContractSpec? = nil
        
        static func loadFromFile(address: String, specPath: String)
        -> indy_besu_vdr_uniffi.ContractConfig
        {
            
            guard let jsonObject = getFile(path: specPath) else {
                fatalError("Could not load JSON file")
            }
            let name = (jsonObject["sourceName"] as! String).substringAfterLast(
                "/"
            ).substringBeforeLast(".")
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: jsonObject["abi"], options: [])
                let abi = String(data: jsonData, encoding: .utf8)
                
                return indy_besu_vdr_uniffi.ContractConfig(
                    address: address,
                    specPath: nil,
                    spec: ContractSpec(name: name, abi: abi!)
                )
            } catch let error {
                fatalError("\(error)")
            }
        }
        
        
        private static func getFile(path: String) -> [String: AnyObject]? {
            
            let cleanPath = path
                .replacingOccurrences(of: "/abi/", with: "")
                .replacingOccurrences(of: ".json", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            
            if let path = Bundle.main.path(forResource: cleanPath, ofType: "json") {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: path))
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject]
                    print("✅ ABI loaded: \(cleanPath).json")
                    return json
                } catch {
                    print("⚠️ Error reading JSON \(cleanPath): \(error)")
                    return nil
                }
            } else {
                print("❌ JSON not found: \(cleanPath).json (root bundle)")
            }
            
            return nil
        }
    }
}
    
    class ContractConfigBesu {
        static func loadFromFile(address: String, specPath: String)
            throws -> indy_besu_vdr_uniffi.ContractConfig
        {
            guard let jsonObject = getFile(path: specPath) else {
                throw NSError(domain: "ContractConfigBesu", code: 0,
                              userInfo: [NSLocalizedDescriptionKey: "Could not load JSON file at \(specPath)"])
            }
            
            guard let sourceName = jsonObject["sourceName"] as? String else {
                throw NSError(domain: "ContractConfigBesu", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "Missing 'sourceName' in ABI JSON"])
            }
            
            let name = sourceName.substringAfterLast("/").substringBeforeLast(".")
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: jsonObject["abi"] as Any, options: [])
                guard let abi = String(data: jsonData, encoding: .utf8) else {
                    throw NSError(domain: "ContractConfigBesu", code: 2,
                                  userInfo: [NSLocalizedDescriptionKey: "Failed to encode ABI"])
                }
                
                return indy_besu_vdr_uniffi.ContractConfig(
                    address: address,
                    specPath: nil,
                    spec: ContractSpec(name: name, abi: abi)
                )
            } catch {
                throw NSError(domain: "ContractConfigBesu", code: 3,
                              userInfo: [NSLocalizedDescriptionKey: "Error parsing ABI: \(error.localizedDescription)"])
            }
        }

        private static func getFile(path: String) -> [String: AnyObject]? {
            let cleanPath = path.replacingOccurrences(of: "/", with: "")
                .replacingOccurrences(of: ".json", with: "")

            let directory = (path as NSString).deletingLastPathComponent
            let fileName = ((path as NSString).lastPathComponent as NSString).deletingPathExtension

            if let path = Bundle.main.path(forResource: fileName, ofType: "json",
                                           inDirectory: directory.isEmpty ? nil : directory) {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                    let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                    return jsonResult as? [String: AnyObject]
                } catch {
                    print("⚠️ Error reading JSON: \(error)")
                    return nil
                }
            } else {
                print("❌ JSON not found at path: \(path)")
            }
            return nil
        }
        
}

 

extension String {
    func substringAfterLast(_ character: Character) -> String {
        if let index = self.lastIndex(of: character) {
            let afterEqualsTo = String(self.suffix(from: index).dropFirst())
            return afterEqualsTo
        }
        return self
    }
    func substringBeforeLast(_ character: String) -> String {
        if let range = self.range(of: character) {
            let beforeStr = self[..<range.lowerBound]
            return String(beforeStr)
        }
        return self
    }

}
