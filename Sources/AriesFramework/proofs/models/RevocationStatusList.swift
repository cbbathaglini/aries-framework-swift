import Foundation

public struct RevocationStatusList: Codable  {
    public let issuerId: String
    public let currentAccumulator: String
    public let revRegDefId: String
    public let revocationList: [UInt32]
    public let timestamp: Int
    
    public init(
            issuerId: String,
            currentAccumulator: String,
            revRegDefId: String,
            revocationList: [UInt32],
            timestamp: Int
        ) {
            self.issuerId = issuerId
            self.currentAccumulator = currentAccumulator
            self.revRegDefId = revRegDefId
            self.revocationList = revocationList
            self.timestamp = timestamp
        }
}

extension RevocationStatusList{
    public func toString() throws -> String {
        let data = try JSONEncoder().encode(self)
        return String(data: data, encoding: .utf8)!
    }
    
    public static func fromJson(_ json: String) throws -> RevocationStatusList {
        let data = Data(json.utf8)
        return try JSONDecoder().decode(RevocationStatusList.self, from: data)
    }
}
