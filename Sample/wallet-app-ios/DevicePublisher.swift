//
//  DevicePublisher.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 19/11/25.
//

import Foundation
import UIKit

class DevicePublisher {
    private var service: NetService?

    func start(port: Int = 8080) {
        let name = UIDevice.current.name

        service = NetService(
            domain: "local.",
            type: "_walletxfer._tcp.",
            name: name,
            port: Int32(port)
        )

        service?.publish()
    }

    func stop() {
        service?.stop()
    }
}
