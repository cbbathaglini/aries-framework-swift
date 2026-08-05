//
//  CredentialFormatCoordinator.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation
import os.log

public final class CredentialFormatCoordinator {
    public let agent: Agent
    public let formatServices: [any CredentialFormatService]
    private let logger = Logger(subsystem: "org.hyperledger.ariesframework", category: "CredentialFormatCoordinator")
    

    public init(agent: Agent, formatServices: [any CredentialFormatService]? = nil) {
        self.agent = agent
        if let services = formatServices {
            self.formatServices = services
        } else {
            self.formatServices = [
                AnoncredsCredentialFormatService(agent: agent) as any CredentialFormatService
            ]
        }
    }
    
    public func createProposal(params: CreateProposalParams) async throws
    -> (ProposeCredentialMessageV2)
    {
    
        let credentialFormats = params.credentialFormats
        let formatServices = params.formatServices
        let credentialRecord = params.credentialRecord
        let comment = params.comment
        let goalCode = params.goalCode
        let goal = params.goal

        var formats: [Format] = []
        var proposalAttachments: [Attachment] = []
        var credentialPreview: CredentialPreviewV2? = nil

        for formatService in formatServices {
            let result = try await formatService.createProposal(
                credentialFormats: credentialFormats,
                credentialExchangeRecord: credentialRecord
            )

            if let preview = result.previewAttribute {
                credentialPreview = CredentialPreviewV2(attributes: preview)
            }

            proposalAttachments.append(result.attachment)
            formats.append(result.format)
        }

        credentialRecord.credentialAttributes = credentialPreview?.attributes

        let message = ProposeCredentialMessageV2(
            formats: formats,
            proposalAttachments: proposalAttachments,
            credentialPreview: credentialPreview,
            goalCode: goalCode,
            goal: goal,
            comment: comment
        )

        message.id = credentialRecord.threadId

        message.setThread(
            threadId: credentialRecord.threadId,
            parentThreadId: credentialRecord.parentThreadId
        )

        try await agent.didCommMessageRepository.saveAgentMessage(
            role: .Sender,
            agentMessage: message,
            associatedRecordId: credentialRecord.id
        )

        return message
    }
    
    public func processProposal( credentialExchangeRecord: CredentialExchangeRecord,
                                 message: ProposeCredentialMessageV2,
                                 formatServices: [any CredentialFormatService]) async throws
    {
        for formatService in formatServices {
            let attachment = try getAttachmentForService(
                credentialFormatService: formatService,
                formats: message.formats,
                attachments: message.proposalAttachments
            )

            try await formatService.processProposal(
                attachment: attachment,
                credentialRecord: credentialExchangeRecord
            )
        }

        try await agent.didCommMessageRepository.saveOrUpdateAgentMessage(
            role: .Receiver,
            agentMessage: message,
            associatedRecordId: credentialExchangeRecord.id
        )
    }
    
    public func acceptProposal(params: AcceptProposalParams) async throws
    -> (OfferCredentialMessageV2)
    {
        let credentialExchangeRecord = params.credentialRecord
            
        var formats: [Format] = []
        var offerAttachments: [Attachment] = []
        var credentialPreview: CredentialPreviewV2? = nil
        
        guard let proposalMessage: ProposeCredentialMessageV2 =
            try await agent.didCommMessageRepository.getTypedAgentMessage(
                associatedRecordId: credentialExchangeRecord.id,
                messageType: ProposeCredentialMessageV2.type,
                role: .Receiver // DidCommMessageRole.Receiver
            ) else {
            throw CredoError("Proposal message not found")
        }
        
        credentialExchangeRecord.credentialAttributes = proposalMessage.credentialPreview?.attributes
        
        for formatService in formatServices {
            let proposalAttachment = try getAttachmentForService(
                credentialFormatService: formatService,
                formats: proposalMessage.formats,
                attachments: proposalMessage.proposalAttachments
            )
            
            let credentialFormatCreateOffer = try await formatService.acceptProposal(
                attachmentId: nil, //if needed can pass a specific id
                credentialFormats: params.credentialFormats,
                credentialRecord: credentialExchangeRecord,
                proposalAttachments: proposalAttachment
            )
            
            let previewAttributes = credentialFormatCreateOffer.previewAttributes
            if !previewAttributes.isEmpty {
                credentialPreview = CredentialPreviewV2(attributes: previewAttributes)
            }
            
            offerAttachments.append(credentialFormatCreateOffer.attachment)
            formats.append(credentialFormatCreateOffer.format)
        }
        
        credentialExchangeRecord.credentialAttributes = credentialPreview?.attributes
        
        if credentialPreview == nil {
            credentialPreview = CredentialPreviewV2(attributes: [])
        }
        
        let message = OfferCredentialMessageV2(
            formats: formats,
            offerAttachments: offerAttachments,
            goalCode: params.goalCode,
            goal: params.goal,
            comment: params.comment,
            credentialPreview: credentialPreview!
        )
        
        message.setThread(
            threadId: credentialExchangeRecord.threadId,
            parentThreadId: credentialExchangeRecord.parentThreadId
        )
        
        try await agent.didCommMessageRepository.saveOrUpdateAgentMessage(
            role: .Sender,
            agentMessage: message,
            associatedRecordId: credentialExchangeRecord.id
        )
        
        return message
    }
    
    public func createOffer(params: CreateCredentialParams) async throws
    -> (OfferCredentialMessageV2)
    {
        var formats: [Format] = []
        var offerAttachments: [Attachment] = []
        var credentialPreview: CredentialPreviewV2? = nil
        
        let credentialExchangeRecord = params.credentialRecord
        let credentialFormat = params.credentialFormats
        
        for formatService in formatServices {
            let offerCreated = try await formatService.createOffer(
                credentialFormats: credentialFormat,
                credentialExchangeRecord: credentialExchangeRecord,
                attachmentId: formatService.formatKey // revisar
            )
            
            if !offerCreated.previewAttributes.isEmpty {
                credentialPreview = CredentialPreviewV2(attributes: offerCreated.previewAttributes)
            }
            
            offerAttachments.append(offerCreated.attachment)
            formats.append(offerCreated.format)
        }
        
        credentialExchangeRecord.credentialAttributes = credentialPreview?.attributes
        
        if credentialPreview == nil {
            credentialPreview = CredentialPreviewV2(attributes: [])
        }
        
        let message = OfferCredentialMessageV2(
            formats: formats,
            offerAttachments: offerAttachments,
            goalCode: params.goalCode,
            goal: params.goal,
            comment: params.comment,
            credentialPreview: credentialPreview,
        )
        
        message.setThread(
            threadId: credentialExchangeRecord.threadId,
            parentThreadId: credentialExchangeRecord.parentThreadId
        )
        
        try await agent.didCommMessageRepository.saveOrUpdateAgentMessage(
            role: .Sender,
            agentMessage: message,
            associatedRecordId: credentialExchangeRecord.id
        )
        
        return message
    }
    
    public func processOffer(params: ProcessOfferParams) async throws
    {
        logDebug("Processing offer: \(params.description)")
            
        let credentialExchangeRecord = params.credentialExchangeRecord
        let formatServices = params.formatService
        let message = params.message

        for formatService in formatServices {
            let attachment = try getAttachmentForService(
                credentialFormatService: formatService,
                formats: message.formats,
                attachments: message.offerAttachments
            )
            
            try await formatService.processOffer(
                attachment: attachment,
                credentialExchangeRecord: credentialExchangeRecord
            )
        }

        try await agent.didCommMessageRepository.saveOrUpdateAgentMessage(
            role: .Receiver,
            agentMessage: message,
            associatedRecordId: credentialExchangeRecord.id
        )
        
        logDebug("Saved or updated agent message")
    }
    
    public func acceptOffer(params: AcceptOfferParams) async throws
    -> RequestCredentialMessageV2
    {
        let credentialExchangeRecord = params.credentialRecord
        logDebug("credentialExchangeRecord: \(credentialExchangeRecord)")

        var formats: [Format] = []
        var requestAttachment: [Attachment] = []
        var requestAppendAttachments: [Attachment] = []

        guard let offerMessage: OfferCredentialMessageV2 = try await agent.didCommMessageRepository.getTypedAgentMessage(
            associatedRecordId: credentialExchangeRecord.id,
            messageType: OfferCredentialMessageV2.type,
            role: .Receiver
        ) else {
            throw CredoError("Offer message not found")
        }

    
        for format in offerMessage.formats {
            guard let service = findFormatService(format: format.attachId) else {
                continue
            }

            let attachment = try getAttachmentForService(
                credentialFormatService: service,
                formats: offerMessage.formats,
                attachments: offerMessage.offerAttachments
            )

            let acceptedOffer = try await service.acceptOffer(
                attachment: attachment,
                credentialExchangeRecord: credentialExchangeRecord,
                credentialFormats: params.credentialFormats,
                attachmentId: format.attachId,
                offerCredentialMessageV2: offerMessage
            )

            requestAttachment.append(acceptedOffer.attachment)
            formats.append(acceptedOffer.format)
            requestAppendAttachments.append(contentsOf: acceptedOffer.appendAttachment ?? [])

            logDebug("credentialExchangeRecord credential format: \(credentialExchangeRecord)")
        }

        credentialExchangeRecord.credentialAttributes = offerMessage.credentialPreview?.attributes

        let requestMessage = RequestCredentialMessageV2(
            formats: formats,
            attachments: requestAppendAttachments,
            requestAttachments: requestAttachment,
            goalCode: params.goalCode,
            goal: params.goal,
            comment: params.comment
        )

        requestMessage.setThread(
            threadId: credentialExchangeRecord.threadId,
            parentThreadId: credentialExchangeRecord.parentThreadId
        )

        try await agent.didCommMessageRepository.saveOrUpdateAgentMessage(
            role: .Sender,
            agentMessage: requestMessage,
            associatedRecordId: credentialExchangeRecord.id
        )

        logDebug("saveOrUpdateAgentMessage in acceptOffer")

        return requestMessage
    }
    
    
    public func createRequest(params: RequestCredentialParams) async throws
    -> (RequestCredentialMessageV2)
    {
        let credentialExchangeRecord = params.credentialRecord
        var formats: [Format] = []
        var requestAttachments: [Attachment] = []

        logDebug("-create request-")

        for formatService in formatServices {
            let result = try await formatService.createRequest(
                credentialFormats: params.credentialFormats,
                credentialExchangeRecord: credentialExchangeRecord
            )
            logDebug("credentialFormatCreateReturn: \(result)")
            requestAttachments.append(result.attachment)
            formats.append(result.format)
        }

        let message = RequestCredentialMessageV2(
            formats: formats,
            attachments: [],
            requestAttachments: requestAttachments,
            goalCode: params.goalCode,
            goal: params.goal,
            comment: params.comment
        )

        message.setThread(
            threadId: credentialExchangeRecord.threadId,
            parentThreadId: credentialExchangeRecord.parentThreadId
        )

        try await agent.didCommMessageRepository.saveOrUpdateAgentMessage(
            role: .Sender,
            agentMessage: message,
            associatedRecordId: credentialExchangeRecord.id
        )

        return message
    }
    
    public func processRequest(params: ProcessRequestParams) async throws
    {
        let credentialExchangeRecord = params.credentialExchangeRecord
        let formatServices = params.formatService
        let requestMessage = params.message

        for formatService in formatServices {
            let attachment = try getAttachmentForService(
                    credentialFormatService: formatService,
                    formats: requestMessage.formats,
                    attachments: requestMessage.requestAttachments
                )

            try await formatService.processRequest(
                attachment: attachment,
                credentialExchangeRecord: credentialExchangeRecord
            )
        }

        try await agent.didCommMessageRepository.saveOrUpdateAgentMessage(
            role: .Receiver,
            agentMessage: requestMessage,
            associatedRecordId: credentialExchangeRecord.id
        )
    }
    
    public func acceptRequest(params: AcceptRequestParams) async throws
    -> (IssueCredentialMessageV2)
    {
        let credentialExchangeRecord = params.credentialExchangeRecord
        let credentialFormats = params.credentialFormat

        guard let requestMessage: RequestCredentialMessageV2 = try await agent.didCommMessageRepository.getTypedAgentMessage(
            associatedRecordId: credentialExchangeRecord.id,
            messageType: RequestCredentialMessageV2.type,
            role: .Receiver
        ) else {
            throw AriesFrameworkError.frameworkError("Request message not found")
        }

        guard let offerMessage: OfferCredentialMessageV2 = try await agent.didCommMessageRepository.getTypedAgentMessage(
            associatedRecordId: credentialExchangeRecord.id,
            messageType: OfferCredentialMessageV2.type,
            role: .Sender
        ) else {
            throw AriesFrameworkError.frameworkError("Offer message not found")
        }

        var formats: [Format] = []
        var credentialAttachments: [Attachment] = []

        for formatService in formatServices {
            let requestAttachment = try getAttachmentForService(
                credentialFormatService: formatService,
                formats: requestMessage.formats,
                attachments: requestMessage.requestAttachments
            )

            let offerAttachment = try getAttachmentForService(
                credentialFormatService: formatService,
                formats: offerMessage.formats,
                attachments: offerMessage.offerAttachments
            )

            let acceptedRequest = try await formatService.acceptRequest(
                requestAttachment: requestAttachment,
                offerAttachment: offerAttachment,
                credentialExchangeRecord: credentialExchangeRecord,
                credentialFormats: credentialFormats,
                requestAppendAttachments: requestMessage.attachments,
                attachmentId: formatService.formatKey //revisar
            )

            credentialAttachments.append(acceptedRequest.attachment)
            formats.append(acceptedRequest.format)
        }

        let issueMessage = IssueCredentialMessageV2(
            formats: formats,
            credentialAttachments: credentialAttachments,
            goalCode: params.goalCode,
            goal: params.goal,
            comment: params.comment
        )

        issueMessage.setThread(
            threadId: credentialExchangeRecord.threadId,
            parentThreadId: credentialExchangeRecord.parentThreadId
        )

        issueMessage.setPleaseAck()

        try await agent.didCommMessageRepository.saveOrUpdateAgentMessage(
            role: .Sender,
            agentMessage: issueMessage,
            associatedRecordId: credentialExchangeRecord.id
        )

        return issueMessage
    }
    
    public func processCredential(params: ProcessCredentialParams) async throws
    {
        let issueMessage = params.message
        logDebug("issue message >> \(issueMessage)")
        logDebug("issue format >> \(issueMessage.formats.first?.format ?? "N/A")")
        logDebug("issue attachment >> \(issueMessage.credentialAttachments.first?.id ?? "N/A")")

        let requestMessage = params.requestCredentialMessageV2
        let credentialExchangeRecord = params.credentialExchangeRecord
        let formatServices = params.formatService

        let metadataValue = credentialExchangeRecord.metadata[MetadataKeys.anonCredsCredentialRequestMetadataKey]?.value
        let metadataString = metadataValue as? String ?? "nil"
        logDebug("credentialExchange AnonCredsCredentialRequestMetadataKey => \(metadataString)")

        guard let offerMessage: OfferCredentialMessageV2 = try await agent.didCommMessageRepository.getTypedAgentMessage(
            associatedRecordId: credentialExchangeRecord.id,
            messageType: OfferCredentialMessageV2.type,
            role: .Receiver
        ) else {
            throw AriesFrameworkError.frameworkError("Offer message not found")
        }

        for formatService in formatServices {
            let offerAttachment = try getAttachmentForService(
                credentialFormatService: formatService,
                formats: offerMessage.formats,
                attachments: offerMessage.offerAttachments
            )
            logDebug("offerAttachment: \(offerAttachment.id)")

            let issueAttachment = try getAttachmentForService(
                credentialFormatService: formatService,
                formats: issueMessage.formats,
                attachments: issueMessage.credentialAttachments
            )
            logDebug("issueAttachment enco: \(issueAttachment.id)")

            let requestAttachment = try getAttachmentForService(
                credentialFormatService: formatService,
                formats: requestMessage.formats,
                attachments: requestMessage.requestAttachments
            )
            logDebug("requestAttachment: \(requestAttachment.id)")

            try await formatService.processCredential(
                attachment: issueAttachment,
                offerAttachment: offerAttachment,
                requestAttachment: requestAttachment,
                credentialExchangeRecord: credentialExchangeRecord,
                requestAppendAttachments: requestMessage.attachments
            )
        }

    
        try await agent.didCommMessageRepository.saveOrUpdateAgentMessage(
            role: .Receiver,
            agentMessage: issueMessage,
            associatedRecordId: credentialExchangeRecord.id
        )
    }
    
    private func findFormatService(format: String) -> (any CredentialFormatService)? {
        return formatServices.first { $0.formatKey == format }
    }
    
    func getAttachmentIdForService(
        credentialFormatService: any CredentialFormatService,
        formats: [Format]
    ) throws -> String {
        guard let format = formats.first(where: { credentialFormatService.supportsFormat($0.format) }) else {
            throw CredoError("No attachment found for service \(credentialFormatService.formatKey)")
        }
        return format.attachId
    }
    
    func getAttachmentForService(
        credentialFormatService: any CredentialFormatService,
        formats: [Format],
        attachments: [Attachment]
    ) throws -> Attachment {
        let attachmentId = try getAttachmentIdForService(credentialFormatService: credentialFormatService, formats: formats)
        guard let attachment = attachments.first(where: { $0.id == attachmentId }) else {
            throw CredoError("Attachment with id \(attachmentId) not found in attachments.")
        }
        
        print("Attachment data: \(attachment.data)")
        return attachment
    }
}
