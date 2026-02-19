//
//  InvitationHandelr.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 12/10/25.
//

import Foundation
import SwiftUI
import AriesFramework

@MainActor
class InvitationHandler: ObservableObject {
    static let shared = InvitationHandler()
    
    private init() {}

    func generateInvitation(label: String) async throws -> String {
        guard var mediatorUrl = Bundle.main.object(forInfoDictionaryKey: "MEDIATOR_URL") as? String else {
            fatalError("MEDIATOR_URL not founded in Info.plist")
        }

        mediatorUrl = mediatorUrl.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        
        var deviceId: String = "Device_R" + UUID().uuidString
        if let idfv = UIDevice.current.identifierForVendor?.uuidString {
            deviceId = "Device_\(idfv)"
        }
        
        let config = CreateOutOfBandInvitationConfig(
            label: deviceId,
            handshake: true,
        )
        
        let outOfBandRecord = try await agent!.oob.createInvitation(config: config)
        let mediatorBaseUrl = mediatorUrl.components(separatedBy: "?").first ?? mediatorUrl
        return try outOfBandRecord.outOfBandInvitation.toUrl(domain: mediatorBaseUrl)
    }
}
