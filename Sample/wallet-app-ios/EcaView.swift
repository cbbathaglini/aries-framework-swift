//
//  W3cCredentialView.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 03/03/26.
//


import SwiftUI
import AriesFramework
import anoncreds_uniffi

// MARK: - ViewModel (igual Kotlin Activity + adapter)

@MainActor
final class EcaViewModel: ObservableObject {

    enum Action {
        case save, list, search, deleteById, deleteAll
    }

    @Published var vcJson: String = ""
    @Published var subjectId: String = ""

    @Published var resultText: String = ""
    @Published var records: [W3cCredentialRecordUI] = []

    @Published var isLoadingAction: Action? = nil

    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    private func popup(_ msg: String) {
        alertMessage = msg
        showAlert = true
    }

    private func setLoading(_ action: Action?) {
        isLoadingAction = action
    }

    func saveCredential() {
        guard let agent = agent else { return }

        let raw = vcJson.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            popup("Cole o JSON da credencial.")
            return
        }

        setLoading(.save)

        Task {
            defer { setLoading(nil) }

            do {
                
                let savedRecord = try await agent.ecaService.saveText(text: raw)
                
                let all = try await agent.ecaService.getAll() ?? []
                self.records = all.compactMap { record in
                    W3cCredentialRecordUI.from(record: record)
                }

//                // 1) salva a credencial W3C
//                let savedRecord = try await agent.w3cCredentialService.processAndStorew3cCredential(rawJson: raw)
//                self.resultText = "Salvo com sucesso.\n(id detectado: \(savedRecord.id))"
//
//                // ------------ TESTE REVERT TO ANONCREDS CREDENTIAL ------------
//                let parsed = try parseJsonObject(raw)
//
//                // 3) alguns fluxos colam { "credential": { ...VC... } } e outros colam a VC direto
//                let credentialJson: Any
//                if let inner = parsed["credential"] {
//                    credentialJson = inner
//                } else {
//                    credentialJson = parsed
//                }
//
//                let credential = try CredentialConversions().credentialFromW3cJson(w3cCredentialJson: raw)
//                print("credentialW3cStr: \(credential.toJson())")
//                // ------------ FIM DO TESTE ------------
//
//                // 5) recarrega lista
//                let all = try await agent.w3cCredentialService.getAll()
//                self.records = all.map { W3cCredentialRecordUI.from(record: $0) }

            } catch {
                popup("Erro ao salvar: \(error.localizedDescription)")
            }
        }
    }

    ///remover
    private func parseJsonObject(_ raw: String) throws -> [String: Any] {
        guard let data = raw.data(using: .utf8) else {
            throw NSError(domain: "W3cCredentialService", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8"])
        }
        let any = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        guard let obj = any as? [String: Any] else {
            throw NSError(domain: "W3cCredentialService", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Expected JSON object"])
        }
        return obj
    }
    func listAll() {
        guard let agent = agent else { return }

        setLoading(.list)
        
        Task {
           do {
               let all = try await agent.ecaService.getAll() ?? []
               self.records = all.compactMap { record in
                   W3cCredentialRecordUI.from(record: record)
               }
               self.resultText = "Total: \(all.count)"
           } catch {
               popup("Erro ao listar: \(error.localizedDescription)")
           }

           setLoading(nil)
       }

//        Task {
//            do {
//                let all = try await agent.w3cCredentialService.getAll()
//                self.records = all.map { W3cCredentialRecordUI.from(record: $0) }
//                self.resultText = "Total: \(all.count)"
//            } catch {
//                popup("Erro ao listar: \(error.localizedDescription)")
//            }
//
//            setLoading(nil)
//        }
    }
    
    func deleteBySubjectId() {
        guard let agent = agent else { return }

        let subjectId = subjectId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !subjectId.isEmpty else {
            popup("Digite um id para deletar.")
            return
        }

        setLoading(.deleteById)

        Task {
            defer { setLoading(nil) }

            do {
                try await agent.ecaService.deleteById(subjectId)

                let all = try await agent.ecaService.getAll() ?? []
                self.records = all.compactMap { record in
                    W3cCredentialRecordUI.from(record: record)
                }

                self.resultText = "Registros deletados para subjectId=\(subjectId)"
            } catch {
                popup("Erro ao deletar por id: \(error.localizedDescription)")
            }
        }
    }

    func deleteAll() {
        guard let agent = agent else { return }

        setLoading(.deleteAll)

        Task {
            defer { setLoading(nil) }

            do {
                try await agent.ecaService.deleteAll()
                self.records = []
                self.resultText = "Todos os registros foram deletados."
            } catch {
                popup("Erro ao deletar tudo: \(error.localizedDescription)")
            }
        }
    }

    func searchBySubjectId() {
        guard let agent = agent else { return }

        let subjectId = subjectId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !subjectId.isEmpty else {
            popup("Digite um id para buscar.")
            return
        }

        setLoading(.search)
        
        Task {
            do {
                let hits = try await agent.ecaService.getBySubjectId(subjectId)

                if hits.count == 0 {
                    self.records = []
                    self.resultText = "Nada encontrado para subjectId=\(subjectId)"
                } else {
                    self.records = hits.map {
                        W3cCredentialRecordUI.from(record: $0)
                    }
                    self.resultText = "Encontrada!!"
                }
            } catch {
                popup("Erro ao buscar: \(error.localizedDescription)")
            }

            setLoading(nil)
        }

//        Task {
//            do {
//                let hits = try await agent.w3cCredentialService.findByCredentialSubjectId(subjectId: q)
//
//                if hits.isEmpty {
//                    self.records = []
//                    self.resultText = "Nada encontrado para subjectId=\(q)"
//                } else {
//                    self.records = hits.map { W3cCredentialRecordUI.from(record: $0) }
//                    self.resultText = "Encontradas: \(hits.count)"
//                }
//            } catch {
//                popup("Erro ao buscar: \(error.localizedDescription)")
//            }
//
//            setLoading(nil)
//        }
    }
}

// MARK: - View (UI igual Activity + layout)

struct EcaView: View {

    @StateObject private var vm = EcaViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cole aqui o JSON da W3C Verifiable Credential")
                            .font(.headline)

                        TextEditor(text: $vm.vcJson)
                            .font(.system(.footnote, design: .monospaced))
                            .frame(minHeight: 180)
                            .padding(12)
                            .background(Color.gray.opacity(0.12))
                            .cornerRadius(12)
                            .textSelection(.enabled)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Credential Subject ID (did:jwk:...)")
                            .font(.headline)

                        TextField("Digite um id para buscar", text: $vm.subjectId)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }

                    VStack(spacing: 10) {

                        Button { vm.saveCredential() } label: {
                            PrimaryButtonLabel(
                                title: "Salvar (Askar)",
                                isLoading: vm.isLoadingAction == .save
                            )
                        }
                        .disabled(vm.isLoadingAction != nil)

                        Button { vm.listAll() } label: {
                            PrimaryButtonLabel(
                                title: "Listar todas",
                                isLoading: vm.isLoadingAction == .list
                            )
                        }
                        .disabled(vm.isLoadingAction != nil)

                        Button { vm.searchBySubjectId() } label: {
                            PrimaryButtonLabel(
                                title: "Buscar por ID",
                                isLoading: vm.isLoadingAction == .search
                            )
                        }
                        .disabled(vm.isLoadingAction != nil)
                    }
                    
                    Button { vm.deleteBySubjectId() } label: {
                        PrimaryButtonLabel(
                            title: "Deletar por ID",
                            isLoading: vm.isLoadingAction == .deleteById
                        )
                    }
                    .disabled(vm.isLoadingAction != nil)

                    Button { vm.deleteAll() } label: {
                        PrimaryButtonLabel(
                            title: "Deletar todas",
                            isLoading: vm.isLoadingAction == .deleteAll
                        )
                    }
                    .disabled(vm.isLoadingAction != nil)
                    
                    if !vm.resultText.isEmpty {
                        Text(vm.resultText)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                    }

                
                    if !vm.records.isEmpty {
                        Divider().padding(.top, 6)

                        LazyVStack(spacing: 12) {
                            ForEach(vm.records) { rec in
                                W3cCredentialCard(rec: rec)
                            }
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(16)
            }
            .navigationTitle("W3C Credentials")
            .alert("Info", isPresented: $vm.showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.alertMessage)
            }
        }
    }
}

// MARK: - Button (igual Material button)

private struct PrimaryButtonLabel: View {
    let title: String
    let isLoading: Bool

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView().tint(.white)
            } else {
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue)
        .cornerRadius(10)
    }
}

// MARK: - Card (item do adapter)

struct W3cCredentialCard: View {
    let rec: W3cCredentialRecordUI

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .top) {
                Text(rec.title)
                    .font(.headline)

                Spacer()

                Text(rec.createdAtText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Divider().opacity(0.35)

            ScrollView(.vertical) {
                Text(rec.rawJson)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 220)
        }
        .padding(14)
        .background(Color.gray.opacity(0.12))
        .cornerRadius(12)
    }
}

struct W3cCredentialRecordUI: Identifiable {
    let id: String
    let title: String
    let createdAtText: String
    let rawJson: String
    
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()
    
    static func from(record: EcaRecord) -> W3cCredentialRecordUI {
        W3cCredentialRecordUI(
            id: record.id,
            title: "ECA Credential",
            createdAtText: formatter.string(from: record.createdAt),
            rawJson: record.credentialText
        )
    }
}

//struct W3cCredentialCard: View {
//    let rec: W3cCredentialRecordUI
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//
//            HStack(alignment: .top) {
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(rec.title)
//                        .font(.headline)
//
//                    if let issuer = rec.issuer, !issuer.isEmpty {
//                        Text("Issuer: \(issuer)")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                            .lineLimit(1)
//                    }
//                }
//
//                Spacer()
//
//                Text(rec.createdAtText)
//                    .font(.caption2)
//                    .foregroundColor(.secondary)
//            }
//
//            Divider().opacity(0.35)
//
//            keyValue("recordId", rec.id)
//
//            if let subjectId = rec.subjectId, !subjectId.isEmpty {
//                keyValue("subjectId", subjectId)
//            }
//
//            if let givenId = rec.givenId, !givenId.isEmpty {
//                keyValue("givenId", givenId)
//            }
//
//            if !rec.types.isEmpty {
//                keyValue("types", rec.types.joined(separator: ", "))
//            }
//        }
//        .padding(14)
//        .background(Color.gray.opacity(0.12))
//        .cornerRadius(12)
//        .textSelection(.enabled)
//    }
//
//    private func keyValue(_ k: String, _ v: String) -> some View {
//        HStack(alignment: .top, spacing: 10) {
//            Text(k)
//                .font(.caption2)
//                .foregroundColor(.secondary)
//                .frame(width: 88, alignment: .leading)
//
//            Text(v)
//                .font(.caption)
//                .foregroundColor(.primary)
//                .lineLimit(3)
//        }
//    }
//}

// MARK: - UI Model (equivalente ao item do adapter)

//struct W3cCredentialRecordUI: Identifiable, Equatable {
//    let id: String
//    let givenId: String?
//    let subjectId: String?
//    let issuer: String?
//    let types: [String]
//    let createdAt: Date?
//
//    var title: String {
//        if types.isEmpty { return "Verifiable Credential" }
//        return types.prefix(2).joined(separator: " • ")
//    }
//
//    var createdAtText: String {
//        guard let createdAt else { return "" }
//        return createdAt.formatted(date: .abbreviated, time: .shortened)
//    }
//
//    static func from(record: W3cCredentialRecord) -> W3cCredentialRecordUI {
//        let subject = record.credential.credentialSubject.first?.id
//        let issuer = String(describing: record.credential.issuer)
//
//        return .init(
//            id: record.id,
//            givenId: record.credential.id,
//            subjectId: subject,
//            issuer: issuer,
//            types: record.credential.type,
//            createdAt: record.createdAt
//        )
//    }
//}
