//
//  GenericalLog.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 08/10/25.
//

import Foundation
import os

let logger = Logger(subsystem: "AriesFramework", category: "IDD")

func logDebug(
    _ message: String,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    let className = (file as NSString)
        .lastPathComponent
        .replacingOccurrences(of: ".swift", with: "")

    let full = "[\(className)][\(function)] \(message) (line \(line))"

    print("🟢 \(full)")            // 👈 aparece SEMPRE no Xcode
    //logger.info(full)              // 👈 vai para unified logging
}
