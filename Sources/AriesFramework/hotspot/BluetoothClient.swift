//
//  BluetoothClient.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 10/17/25.
//

import CoreBluetooth

public class BluetoothClient: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var discoveredPeripheral: CBPeripheral?
    private var targetCharacteristic: CBCharacteristic?
    
    private let serviceUUID = CBUUID(string: "d14a2b10-9f12-4b2a-b0c1-7b6b2c0a9d99")
    private let characteristicUUID = CBUUID(string: "d14a2b11-9f12-4b2a-b0c1-7b6b2c0a9d99")

    public var onLog: ((String) -> Void)?
    public var onConnected: ((String) -> Void)?

    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - Bluetooth State
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            onLog?("🔍 Scanning for BLE peripherals...")
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
            //centralManager.scanForPeripherals(withServices: nil, options: nil)
        case .poweredOff:
            onLog?("⚠️ Bluetooth is powered off.")
        case .unsupported:
            onLog?("❌ Bluetooth is not supported on this device.")
        default:
            onLog?("⚠️ Unknown Bluetooth state: \(central.state.rawValue)")
        }
    }

    // MARK: - Peripheral Discovery
    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        onLog?("📡 Found: \(peripheral.name ?? "No name") (RSSI: \(RSSI))")
        discoveredPeripheral = peripheral
        discoveredPeripheral?.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }
    
    public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        onLog?("❌ Disconnected from \(peripheral.name ?? "no name"): \(error?.localizedDescription ?? "no error")")
    }

    // MARK: - Connection
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        onLog?("✅ Connected to peripheral \(peripheral.name ?? "unknown")")
        onConnected?(peripheral.name ?? "Unknown")
        
        // ⚙️ Delay to allow Android to finish registering GATT
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.onLog?("🔍 Discovering services after 800ms...")
            peripheral.discoverServices([self.serviceUUID])
            //peripheral.discoverServices(nil)
        }
    }

    public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        onLog?("❌ Failed to connect: \(error?.localizedDescription ?? "unknown error")")
    }

    // MARK: - Service and Characteristic Discovery
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == serviceUUID {
            onLog?("🧭 Service found: \(service.uuid.uuidString)")
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard let characteristic = service.characteristics?
            .first(where: { $0.uuid == characteristicUUID }) else { return }
        targetCharacteristic = characteristic
        onLog?("✍️ Ready to send JSON.")
    }

    // MARK: - JSON Sending
    public func sendJSON(_ json: [String: Any]) {
        guard let peripheral = discoveredPeripheral,
              let characteristic = targetCharacteristic else {
            onLog?("⚠️ No peripheral or characteristic available.")
            return
        }

        guard let data = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            onLog?("❌ Error converting JSON to Data.")
            return
        }

        let mtu = 180
        onLog?("📤 Sending JSON (\(data.count) bytes)...")

        for i in stride(from: 0, to: data.count, by: mtu) {
            let chunk = data.subdata(in: i..<min(i + mtu, data.count))
            peripheral.writeValue(chunk, for: characteristic, type: .withResponse)
            onLog?("➡️ Sent chunk \(i / mtu + 1)")
        }

        peripheral.writeValue("<EOF>".data(using: .utf8)!, for: characteristic, type: .withResponse)
        onLog?("✅ JSON sent successfully.")
    }
}
