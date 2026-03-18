//
//  ProofFormatCoordinator.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/10/25.
//
import Foundation
import os.log

public final class ProofFormatCoordinator : ProofFormatCoordinatorProtocol {
    public let agent: Agent
    public let formatServices: [any ProofFormatService]
    private let logger = Logger(subsystem: "org.hyperledger.ariesframework", category: "ProofFormatCoordinator")
    
    public init(agent: Agent, formatServices: [any ProofFormatService]? = nil) {
        self.agent = agent
        if let services = formatServices {
            self.formatServices = services
        } else {
            self.formatServices = [
                AnoncredsProofFormatService(agent: agent) as any ProofFormatService
            ]
        }
    }
    
    public func createProposal(params: CreateProofProposalParams) async throws -> ProposePresentationMessageV2 {
        let formatServices = params.formatServices
        let proofFormats = params.proofFormats
        let proofRecord = params.proofRecord
        let comment = params.comment
        let goalCode = params.goalCode
        let goal = params.goal

        var formats: [ProofFormatSpec] = []
        var proposalAttachments: [Attachment] = []

        for formatService in formatServices {
            let proofFormatCreateProposalReturn = try await formatService.createProposal(
                profRecord: proofRecord,
                attachmentId: formatService.formatKey,
                proofFormats: proofFormats
            )

            proposalAttachments.append(proofFormatCreateProposalReturn.attachment)
            formats.append(proofFormatCreateProposalReturn.format)
        }

        var message = ProposePresentationMessageV2(
            comment: comment,
            goalCode: goalCode,
            goal: goal,
            proposalAttachments: proposalAttachments,
            formats: formats
        )

        message.id = proofRecord.threadId
        message.setThread(
            threadId: proofRecord.threadId,
            parentThreadId: proofRecord.parentThreadId
        )

        try await agent.didCommMessageRepository.saveOrUpdateAgentMessage(
            role: .Sender,
            agentMessage: message,
            associatedRecordId: proofRecord.id
        )

        return message
    }
    
    public func processProposal(
        proofRecord: ProofExchangeRecord,
        message: ProposePresentationMessageV2,
        formatServices: [any ProofFormatService]
    ) async throws {
        for formatService in formatServices {
            let attachment = try ProofUtils.getAttachmentForService(
                proofFormatService: formatService,
                formats: message.formats,
                attachments: message.proposalAttachments
            )

            try await formatService.processProposal(
                attachment: attachment,
                proofRecord: proofRecord
            )
        }

        try await agent.didCommMessageRepository.saveOrUpdateAgentMessage(
            role: .Receiver,
            agentMessage: message,
            associatedRecordId: proofRecord.id
        )
    }
    
    public func acceptProposal(params: AcceptProofProposalParams) async throws -> RequestPresentationMessageV2 {
        let proofRecord = params.proofRecord
        let proofFormats = params.proofFormats
        let formatServices = params.formatServices
        let comment = params.comment
        let goalCode = params.goalCode
        let goal = params.goal
        let presentMultiple = params.presentMultiple
        let willConfirm = params.willConfirm
        
        
        var formats: [ProofFormatSpec] = []
        var requestAttachments: [Attachment] = []

        guard let proposalMessage: ProposePresentationMessageV2 = try await agent.didCommMessageRepository.getTypedAgentMessage(
            associatedRecordId: proofRecord.id,
            messageType: ProposePresentationMessageV2.type,
            role: .Receiver
        ) else {
            throw CredoError("Proposal message not found")
        }

        for formatService in formatServices {
            let proposalAttachment = try ProofUtils.getAttachmentForService(
                proofFormatService: formatService,
                formats: proposalMessage.formats,
                attachments: proposalMessage.proposalAttachments
            )

           
            let proofAccepted = try await formatService.acceptProposal(
                proofRecord: proofRecord,
                attachmentId: formatService.formatKey,
                proposalAttachment: proposalAttachment,
                proofFormats: proofFormats
            )

            requestAttachments.append(proofAccepted.attachment)
            formats.append(proofAccepted.format)
        }

        let message = RequestPresentationMessageV2(
            comment: comment,
            goal: goal,
            goalCode: goalCode,
            willConfirm: willConfirm,
            presentMultiple: presentMultiple,
            formats: formats,
            requestPresentationAttachments: requestAttachments,
        )

        message.setThread(
            threadId: proofRecord.threadId,
            parentThreadId: proofRecord.parentThreadId
        )

        try await agent.didCommMessageRepository.saveOrUpdateAgentMessage(
            role: .Sender,
            agentMessage: message,
            associatedRecordId: proofRecord.id
        )

        return message
    }
    
    public func createRequest(params: RequestProofRequestParams) async throws -> RequestPresentationMessageV2 {
        logDebug("createRequest in coordinator")

        let proofRecord = params.proofRecord
        let proofFormats = params.proofFormats
        let formatServices = params.formatServices
        let comment = params.comment
        let goalCode = params.goalCode
        let goal = params.goal
        let presentMultiple = params.presentMultiple
        let willConfirm = params.willConfirm
        let attachmentId = params.attachmentId

        logDebug("format service: \(formatServices.first?.formatKey ?? "none")")

        var formats: [ProofFormatSpec] = []
        var requestAttachments: [Attachment] = []

        for formatService in formatServices {
            let result = try await formatService.createRequest(
                proofRecord: proofRecord,
                attachmentId: attachmentId,
                proofFormats: proofFormats
            )

            logDebug("proofFormatCreateProposalReturn: \(result)")

            requestAttachments.append(result.attachment)
            formats.append(result.format)
        }

        logDebug("createRequest after formatService")

        var message = RequestPresentationMessageV2(
            comment: comment,
            goal: goal,
            goalCode: goalCode,
            willConfirm: willConfirm,
            presentMultiple: presentMultiple,
            formats: formats,
            requestPresentationAttachments: requestAttachments
        )
        
        logDebug("RequestPresentationMessageV2 created: \(message)")

        message.setThread(
            threadId: proofRecord.threadId,
            parentThreadId: proofRecord.parentThreadId
        )

        try await agent.didCommMessageRepository.saveAgentMessage(
            role: .Sender,
            agentMessage: message,
            associatedRecordId: proofRecord.id
        )

        return message
    }
    
    public func processRequest(
        proofRecord: ProofExchangeRecord,
        message: RequestPresentationMessageV2,
        formatServices: [any ProofFormatService]
    ) async throws {
        for formatService in formatServices {
            let attachment = try ProofUtils.getAttachmentForService(
                proofFormatService: formatService,
                formats: message.formats,
                attachments: message.requestPresentationAttachments
            ) 

            var options = ProofFormatProcessOptions(
                attachment: attachment,
                proofRecord: proofRecord
            )

            try await formatService.processRequest(options: options)
        }

        logDebug("agent.didCommMessageRepository.saveOrUpdateAgentMessag")
        try await agent.didCommMessageRepository.saveOrUpdateAgentMessage(
            role: .Receiver,
            agentMessage: message,
            associatedRecordId: proofRecord.id
        )
    }
    
    public func acceptRequest(params: AcceptProofRequestParams) async throws -> PresentationMessageV2 {
        let proofRecord = params.proofRecord
        let proofFormats = params.proofFormats
        let formatServices = params.formatServices
        let comment = params.comment
        let lastPresentation = params.lastPresentation
        let goalCode = params.goalCode
        let goal = params.goal
        let chosenCredentialId = params.chosenCredentialId

        logDebug("formats: \(proofFormats)")
        guard let requestMessage: RequestPresentationMessageV2 = try await agent.didCommMessageRepository.getTypedAgentMessage(
            associatedRecordId: proofRecord.id,
            messageType: RequestPresentationMessageV2.type,
            role: .Receiver
        ) else {
            throw CredoError("Request message not found")
        }

        let proposalRaw = try await agent.didCommMessageRepository.findAgentMessage(
            associatedRecordId: proofRecord.id,
            messageType: ProposePresentationMessageV2.type
        )

        let proposalMessage: ProposePresentationMessageV2? = {
            if let proposalRaw {
                return try? MessageSerializer.decodeFromString(proposalRaw) as? ProposePresentationMessageV2
            }
            return nil
        }()

        var formats: [ProofFormatSpec] = []
        var presentationAttachments: [Attachment] = []

        for formatService in formatServices {
            let requestAttachment = try ProofUtils.getAttachmentForService(
                proofFormatService: formatService,
                formats: requestMessage.formats,
                attachments: requestMessage.requestPresentationAttachments
            )
            
            let json = try requestAttachment.getDataAsJson()
            logDebug("request attachment: \(json)")
            let proposalAttachment: Attachment? = {
                if let proposalMessage {
                    return try? ProofUtils.getAttachmentForService(
                        proofFormatService: formatService,
                        formats: proposalMessage.formats,
                        attachments: proposalMessage.proposalAttachments
                    )
                }
                return nil
            }()
            
            guard let unwrappedProofFormats = proofFormats else {
                throw CredoError("proof formats must be not null")
            }


            let proofAccepted = try await formatService.acceptRequest(
                requestMessage: requestMessage,
                proofRecord: proofRecord,
                proofFormats: unwrappedProofFormats,
                attachmentId: formatService.formatKey,
                requestAttachment: requestAttachment,
                proposalAttachment: proposalAttachment,
                chosenCredentialId: chosenCredentialId
            )

            presentationAttachments.append(proofAccepted.attachment)
            formats.append(proofAccepted.format)
        }

        let message = PresentationMessageV2(
            comment: comment,
            goalCode: goalCode,
            goal: goal,
            lastPresentation: lastPresentation,
            formats: formats,
            presentationAttachments: presentationAttachments,
        )
    
        message.setThread(threadId: proofRecord.threadId, parentThreadId: proofRecord.parentThreadId)
        message.setPleaseAck()
        
        logDebug("generate msg: \(message.description)")

        try await agent.didCommMessageRepository.saveOrUpdateAgentMessage(
            role: .Sender,
            agentMessage: message,
            associatedRecordId: proofRecord.id
        )

        return message
    }
    
    public func processPresentation(
        proofRecord: inout ProofExchangeRecord,
        presentationMessage: PresentationMessageV2,
        requestMessage: RequestPresentationMessageV2,
        formatServices: [any ProofFormatService]
    ) async throws -> ProcessPresentationReturn {
        var formatVerificationResults: [Bool] = []

        for formatService in formatServices {
            do {
                let requestAttachment = try ProofUtils.getAttachmentForService(
                    proofFormatService: formatService,
                    formats: requestMessage.formats,
                    attachments: requestMessage.requestPresentationAttachments
                )

                let presentationAttachment = try ProofUtils.getAttachmentForService(
                    proofFormatService: formatService,
                    formats: presentationMessage.formats,
                    attachments: presentationMessage.presentationAttachments
                )
                
                let isValid = try await formatService.processPresentation(
                    requestAttachment: requestAttachment,
                    presentationAttachment: presentationAttachment,
                    proofRecord: &proofRecord,
                    presentationMessage: presentationMessage,
                    requestMessage: requestMessage
                )

                formatVerificationResults.append(isValid)
                
            } catch {
                logger.error("message error: \(error.localizedDescription)")
                return ProcessPresentationReturn(
                    isValid: false,
                    message: error.localizedDescription
                )
            }
        }

        try await agent.didCommMessageRepository.saveOrUpdateAgentMessage(
            role: .Receiver,
            agentMessage: presentationMessage,
            associatedRecordId: proofRecord.id
        )

        let isAllValid = formatVerificationResults.allSatisfy { $0 == true }

        if isAllValid {
            return ProcessPresentationReturn(isValid: true)
        } else {
            return ProcessPresentationReturn(
                isValid: false,
                message: "Not all presentations are valid"
            )
        }
    }
    
}

