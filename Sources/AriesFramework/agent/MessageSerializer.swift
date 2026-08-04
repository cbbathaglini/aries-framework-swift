//
//  MessageSerializer.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 17/03/25.
//

import os
import Foundation

public class MessageSerializer {
    private static var serializers: [String: AgentMessage.Type] = [:]
    private static let logger = Logger(subsystem: "AriesFramework", category: "MessageSerializer")
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        return encoder
    }()
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }()

    public static func registerMessage<T: AgentMessage>(type: String, clazz: T.Type) {
        serializers[type] = clazz
        //serializers[Dispatcher.replaceNewDidCommPrefixWithLegacyDidSov(messageType: type)] = clazz
    }

    public static func selectDeserializer(from json: [String: Any]) -> AgentMessage.Type? {
        guard let type = json["@type"] as? String else {
            logger.error("Message type is missing in JSON")
            return nil
        }
        if let serializer = serializers[type] {
            return serializer
        } else {
            logger.error("Message type \(type) is not registered for JSON decoding")
            return nil
        }
    }


    public static func encodeToString(message: AgentMessage) -> String? {
        guard let serializer = serializers[message.type] else {
            logger.error("Message type \(message.type) is not registered for JSON encoding")
            return nil
        }
        do {
            let jsonData = try encoder.encode(message)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            logger.error("Failed to encode message: \(error)")
            return nil
        }
    }

    public static func decodeFromString(_ jsonString: String) -> AgentMessage? {
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
            guard let deserializer = selectDeserializer(from: jsonObject ?? [:]) else { return nil }
            return try decoder.decode(deserializer, from: jsonData)
        } catch {
            logger.error("Failed to decode message: \(error)")
            return nil
        }
    }
    

}
