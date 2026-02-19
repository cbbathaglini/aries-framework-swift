//
//  BluetoothHandler.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 10/17/25
//

import Foundation
import CoreBluetooth
import SwiftUI
import AriesFramework

@MainActor
class BluetoothHandler: NSObject, ObservableObject {
    @Published var stateText: String = "Unknown"
    @Published var connectedDevice: String? = nil
    @Published var receivedJSON: String? = nil
    @Published var lastReceivedJsonString: String? = nil
    @Published var logs: [String] = []
    @Published var availableDevices: [CBPeripheral] = []
    @Published var isReadyToSend: Bool = false

    private var server: BluetoothServer?
    private var client: BluetoothClient?
    private var centralManager: CBCentralManager?
    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]

    //var onReceiveJSON: (([String: Any]) -> Void)?
    var onReceiveJSON: ((String) -> Void)?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    func switchMode(to mode: BluetoothMode) {
        logs.removeAll()
        receivedJSON = nil
        connectedDevice = nil
        availableDevices.removeAll()

        switch mode {
        case .server:
            client = nil
            setupServerMode()

        case .client:
            server = nil
            setupClientMode()
        }
    }

    private func setupServerMode() {
        server = BluetoothServer()

        server?.onLog = { [weak self] msg in
            self?.logMessage(msg)
        }

        server?.onDeviceConnected = { [weak self] device in
            self?.connectedDevice = device
            self?.stateText = "Connected"
            self?.logMessage("🤝 Client connected: \(device)")
        }

        server?.onJSONReceived = { [weak self] jsonString in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let data = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
                   let prettyText = String(data: pretty, encoding: .utf8) {
                    self.receivedJSON = prettyText
                    self.onReceiveJSON?(prettyText)
                    self.logMessage("📥 Received complete and valid JSON.")
                } else {
                    self.receivedJSON = jsonString
                    self.onReceiveJSON?(jsonString)
                    self.logMessage("⚠️ Received JSON, but it could not be converted.")
                }
            }
        }

        stateText = "Waiting for connections..."
        logMessage("🟢 Server mode started.")
    }

    // MARK: - Client Setup (Android receives)
    private func setupClientMode() {
        client = BluetoothClient()
        client?.onLog = { [weak self] msg in self?.logMessage(msg) }
        client?.onConnected = { [weak self] name in
            self?.connectedDevice = name
            self?.stateText = "Connected"
            self?.logMessage("🤝 Connected to \(name)")
        }

        availableDevices.removeAll()
        discoveredPeripherals.removeAll()
        stateText = "Searching for devices..."
        logMessage("🔵 Client mode started.")
    }

    // MARK: - BLE Scan
    func startScan() {
        guard let centralManager else {
            logMessage("⚠️ Central Manager not initialized.")
            return
        }

        availableDevices.removeAll()
        discoveredPeripherals.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        logMessage("🔍 Starting device scan...")
    }

    // MARK: - Manual Connection
    func connectTo(_ peripheral: CBPeripheral) {
        guard let centralManager else { return }
        centralManager.connect(peripheral, options: nil)
        logMessage("🔗 Connecting to \(peripheral.name ?? "No name")...")
    }

    // MARK: - Send JSON
    func sendJSON(_ json: [String: Any]) {
        guard let client = client else {
            logMessage("⚠️ BLE client not initialized.")
            return
        }
        client.sendJSON(json)
        logMessage("📤 JSON sent.")
    }

    // MARK: - Log helper
    func logMessage(_ msg: String) {
        logs.append(msg)
        print(msg)
    }
}

extension BluetoothHandler: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            stateText = "Bluetooth on"
        case .poweredOff:
            stateText = "Bluetooth off"
        case .unauthorized:
            stateText = "Permission denied"
        default:
            stateText = "Unknown state"
        }
        logMessage("📶 Bluetooth state: \(stateText)")
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        if discoveredPeripherals[peripheral.identifier] == nil {
            discoveredPeripherals[peripheral.identifier] = peripheral
            availableDevices.append(peripheral)
            logMessage("📡 Found: \(peripheral.name ?? "No name")")
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedDevice = peripheral.name ?? "Device"
        isReadyToSend = true
        logMessage("✅ Connected to \(connectedDevice!)")
    }
}
