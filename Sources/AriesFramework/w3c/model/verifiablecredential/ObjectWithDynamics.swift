//
//  ObjectWithDynamics.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 22/04/25.
//

import Foundation

class ObjectWithDynamics {
    var dynamicAttributes: [String: Any?] = [:]
    
    init() {}
    
    func setDynamic(key: String, value: Any?) {
        dynamicAttributes[key] = value
    }
    
    func getDynamic(key: String) -> Any? {
        return dynamicAttributes[key]
    }
    
    func toJson() -> String {
        var result: [String: Any] = [:]
        
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let key = child.label, key != "dynamicAttributes" {
                result[key] = child.value
            }
        }
        
        for (key, value) in dynamicAttributes {
            result[key] = value
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        } else {
            return "{}"
        }
    }
}
