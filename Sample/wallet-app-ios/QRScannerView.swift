//
//  QRScannerView.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 11/03/26.
//

import SwiftUI
import AVFoundation

struct QRScannerView: UIViewRepresentable {
    @Binding var isScanning: Bool
    let onCodeScanned: (String) -> Void

    func makeUIView(context: Context) -> ScannerPreviewView {
        let view = ScannerPreviewView()
        context.coordinator.setupCamera(in: view, isScanning: $isScanning, onCodeScanned: onCodeScanned)
        return view
    }

    func updateUIView(_ uiView: ScannerPreviewView, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        private var session: AVCaptureSession?
        private var previewLayer: AVCaptureVideoPreviewLayer?
        private var onCodeScanned: ((String) -> Void)?
        private var isScanning: Binding<Bool>?

        func setupCamera(
            in view: ScannerPreviewView,
            isScanning: Binding<Bool>,
            onCodeScanned: @escaping (String) -> Void
        ) {
            self.onCodeScanned = onCodeScanned
            self.isScanning = isScanning

            let session = AVCaptureSession()
            self.session = session

            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                return
            }

            if session.canAddInput(input) {
                session.addInput(input)
            }

            let metadataOutput = AVCaptureMetadataOutput()
            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            }

            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = UIScreen.main.bounds
            self.previewLayer = previewLayer

            view.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            view.layer.addSublayer(previewLayer)

            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }

            focusCenter(device: device)
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard isScanning?.wrappedValue == true else { return }

            guard let first = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  first.type == .qr,
                  let value = first.stringValue else {
                return
            }

            onCodeScanned?(value)
        }

        private func focusCenter(device: AVCaptureDevice) {
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                    device.focusMode = .continuousAutoFocus
                }
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = CGPoint(x: 0.5, y: 0.5)
                    device.exposureMode = .continuousAutoExposure
                }
                device.unlockForConfiguration()
            } catch {
                print("Focus error: \(error)")
            }
        }

        deinit {
            session?.stopRunning()
        }
    }
}

final class ScannerPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
}
