//
//  BluetoothServer.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 10/21/25
//

import CoreBluetooth

public class BluetoothServer: NSObject, CBPeripheralManagerDelegate {
    private var peripheralManager: CBPeripheralManager!
    private var transferCharacteristic: CBMutableCharacteristic!
    private var serviceUUID = CBUUID(string: "d14a2b10-9f12-4b2a-b0c1-7b6b2c0a9d99")
    private var characteristicUUID = CBUUID(string: "d14a2b11-9f12-4b2a-b0c1-7b6b2c0a9d99")

    // Buffer to accumulate received data
    private var receivedBuffer = Data()
    private let eofMarker = Data("<EOF>".utf8)

    // Variables for sending (iOS ➜ Android)
    private var pendingData: Data?
    private var sendOffset = 0

    public var onLog: ((String) -> Void)?
    public var onJSONReceived: ((String) -> Void)?
    public var onDeviceConnected: ((String) -> Void)?

    public override init() {
        super.init()
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        onLog?("🚀 PeripheralManager initialized — waiting for .poweredOn state")
    }

    // MARK: - Bluetooth State
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            onLog?("✅ Bluetooth powered on — creating BLE Proof Transfer service")
            setupService()
        case .poweredOff:
            onLog?("⚠️ Bluetooth powered off — enable it in settings.")
        case .unsupported:
            onLog?("❌ This device does not support BLE.")
        case .unauthorized:
            onLog?("🚫 Bluetooth permission not granted.")
        default:
            onLog?("⚠️ Unknown state: \(peripheral.state.rawValue)")
        }
    }

    // MARK: - BLE Service Creation
    private func setupService() {
        onLog?("🧱 Creating service and characteristic...")

        transferCharacteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: [.notify, .write, .writeWithoutResponse],
            value: nil,
            permissions: [.writeable]
        )

        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [transferCharacteristic]
        peripheralManager.add(service)

        onLog?("📦 Service created: \(service.uuid.uuidString)")
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            onLog?("❌ Failed to add service: \(error.localizedDescription)")
            return
        }
        onLog?("🧩 Service added successfully — starting advertising...")
        startAdvertising()
    }

    private func startAdvertising() {
        let advertisingData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: "IDDiOS"
        ]
        peripheralManager.startAdvertising(advertisingData)
        onLog?("📡 Advertising BLE service (UUID + local name via scan response)")
    }

    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            onLog?("❌ Failed to start BLE advertising: \(error.localizedDescription)")
        } else {
            onLog?("✅ BLE advertising started successfully.")
        }
    }

    // MARK: - Connection and Subscription
    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        onLog?("✅ Client connected: \(central.identifier.uuidString)")
        onDeviceConnected?(central.identifier.uuidString)
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        onLog?("❌ Client disconnected: \(central.identifier.uuidString)")
    }

    // MARK: - Write Handling
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        onLog?("📨 didReceiveWrite triggered with \(requests.count) requests")

        for req in requests {
            if let value = req.value {
                handleIncomingData(value) // ✅ uses the method that handles buffering and <EOF>
            }
            peripheral.respond(to: req, withResult: .success)
        }
    }

    private func handleIncomingData(_ data: Data) {
        // accumulate received chunks
        receivedBuffer.append(data)
        onLog?("⬇️ Received \(data.count) bytes (\(receivedBuffer.count) total)")

        // try to convert the entire buffer to string
        guard var text = String(data: receivedBuffer, encoding: .utf8) else { return }

        // check for end-of-file marker
        if text.range(of: "<EOF>") != nil {
            text = text.replacingOccurrences(of: "<EOF>", with: "")
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)

            onLog?("📥 Full JSON received (\(text.count) bytes)")

            // try parsing — if it fails, show raw content
            if let jsonData = text.data(using: .utf8) {
                do {
                    _ = try JSONSerialization.jsonObject(with: jsonData, options: [])
                    onLog?("✅ Valid JSON decoded successfully.")
                    onJSONReceived?(text)
                } catch {
                    onLog?("⚠️ Failed to decode received JSON. Raw content:\n\(text)")
                    onJSONReceived?(text)
                }
            } else {
                onLog?("⚠️ Could not create Data from received string.")
                onJSONReceived?(text)
            }

            // clear buffer for next transmission
            receivedBuffer.removeAll()
        }
    }

    // MARK: - Sending (iOS ➜ Android)
    public func sendJSON(_ json: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            onLog?("❌ Error converting JSON to Data.")
            return
        }

        pendingData = data
        sendOffset = 0
        onLog?("📤 Sending JSON (\(data.count) bytes)...")
        sendNextChunk()
    }

    private func sendNextChunk() {
        guard let pendingData = pendingData else { return }

        let mtu = 512
        let end = min(sendOffset + mtu, pendingData.count)
        let chunk = pendingData.subdata(in: sendOffset..<end)

        let success = peripheralManager.updateValue(
            chunk,
            for: transferCharacteristic,
            onSubscribedCentrals: nil
        )

        if success {
            sendOffset = end
            if sendOffset < pendingData.count {
                sendNextChunk()
            } else {
                onLog?("✅ JSON sent completely (\(pendingData.count) bytes)")
            }
        } else {
            onLog?("⚠️ updateValue failed — buffer full, waiting...")
        }
    }
}
