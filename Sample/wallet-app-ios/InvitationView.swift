import SwiftUI

struct InvitationView: View {
    @State private var invitationURL: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var deviceId: String = ""
    @State private var showCopyAlert = false

    @StateObject private var invitationHandler = InvitationHandler.shared

    var body: some View {
        VStack(spacing: 20) {
            Text("Generate Invitation")
                .font(.title2)
                .bold()
                .padding(.top)
            
            if isLoading {
                ProgressView("Generating invitation...")
                    .padding()
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else if !invitationURL.isEmpty {
                VStack(spacing: 12) {
                    Text("Invitation QR Code")
                        .font(.headline)

                    if let qrImage = generateQRCode(from: invitationURL) {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    }

                    Text("Invitation URL:")
                        .font(.headline)

                    ScrollView(.vertical, showsIndicators: true) {
                        Text(invitationURL)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding()
                            .multilineTextAlignment(.center)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = invitationURL
                                    showCopyAlert = true
                                } label: {
                                    Label("Copy URL", systemImage: "doc.on.doc")
                                }
                            }
                    }
                    .frame(maxHeight: 150)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    Button {
                        UIPasteboard.general.string = invitationURL
                        showCopyAlert = true
                    } label: {
                        Label("Copy Invitation URL", systemImage: "doc.on.doc")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Spacer()
            
            Button(action: {
                Task {
                    isLoading = true
                    errorMessage = nil
                    do {
                        let label = "device_\(deviceId)"
                        let result = try await invitationHandler.generateInvitation(label: label)
                        invitationURL = result
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                    isLoading = false
                }
            }) {
                Label("Generate New Invitation", systemImage: "qrcode")
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
        .padding()
        .navigationTitle("Invitation")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let idfv = UIDevice.current.identifierForVendor?.uuidString {
                deviceId = idfv
                print("identifierForVendor: \(idfv)")
            } else {
                print("⚠️ Unable to obtain identifierForVendor")
            }
        }
     
        .alert("Copied!", isPresented: $showCopyAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The invitation URL has been copied to your clipboard.")
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .utf8)

        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else { return nil }

        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = ciImage.transformed(by: transform)

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    InvitationView()
}
