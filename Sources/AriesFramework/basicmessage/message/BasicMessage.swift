//
//  BasicMessage.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/03/25.
//

import Foundation

public class BasicMessage: AgentMessage {
    public static var type: String = "https://didcomm.org/basicmessage/1.0/message"
    
    public var content: String
    
    private enum CodingKeys: String, CodingKey {
        case content, id, type
    }
    
    public init(id: String? = nil, content: String) {
        self.content = content
        super.init(id: id, type: BasicMessage.type)
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        content = try values.decode(String.self, forKey: .content)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try super.encode(to: encoder)
    }
}
