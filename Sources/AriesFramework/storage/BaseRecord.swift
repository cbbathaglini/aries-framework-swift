
import Foundation
import AnyCodable

public protocol BaseRecord: Identifiable {
    var id: String { get set }
    static var type: String { get }
    var tags: Tags? { get set }
    func getTags() -> Tags
    var metadata: [String: AnyCodable] { get set }
    func addMetadata(key: String, value: AnyCodable)
    func setTags(_ tags: Tags)
}

extension BaseRecord {
    public static func generateId() -> String {
        return UUID().uuidString
    }
    public func addMetadata(key: String, value: AnyCodable) {
        var copy = self
        copy.metadata[key] = value
    }

    public func setTags(_ tags: Tags) {
        var copy = self
        copy.tags = tags
    }
}
