
import Foundation
import os

public class Dispatcher {
    let agent: Agent
    let logger = Logger(subsystem: "AriesFramework", category: "Dispatcher")
    var handlers: [String: MessageHandler] = [:]

    init(agent: Agent) {
        self.agent = agent
        registerProblemReportHandlers()
    }

    public func registerHandler(handler: MessageHandler) {
        handlers[handler.messageType] = handler
        //handlers[Dispatcher.replaceNewDidCommPrefixWithLegacyDidSov(messageType: handler.messageType)] = handler << DEPRECATED
    }

    private func registerProblemReportHandlers() {
        registerHandler(handler: ProblemReportHandler(agent: agent, messageType: PresentationProblemReportMessageV2.type))
        registerHandler(handler: ProblemReportHandler(agent: agent, messageType: PresentationProblemReportMessage.type))
        registerHandler(handler: ProblemReportHandler(agent: agent, messageType: CredentialProblemReportMessage.type))
        registerHandler(handler: ProblemReportHandler(agent: agent, messageType: MediationProblemReportMessage.type))
    }

    func dispatch(messageContext: InboundMessageContext) async throws {
        logDebug("Dispatching message of type: \(messageContext.message.type)")
        guard let handler = handlers[messageContext.message.type] else {
            throw AriesFrameworkError.frameworkError("No handler for message type: \(messageContext.message.type)")
        }
        

        do {
            if let outboundMessage = try await handler.handle(messageContext: messageContext) {
                logDebug("Finishing dispatch with message of type: \(outboundMessage.payload.type)")
                Task {
                    try await agent.messageSender.send(message: outboundMessage)
                }
            } else {
                logDebug("Finishing dispatch without response")
            }
        } catch {
            logger.error("Failed to dispatch message of type: \(messageContext.message.type) ERROR: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func printDispatcherMessages(messageContext: InboundMessageContext) {
        print("message: \(String(describing: messageContext.message))")
        print("plaintextMessage: \(messageContext.plaintextMessage)")
        print("type of message: \(messageContext.message.type)")

        print("all handlers available -->")
        for (key, value) in handlers {
            print("Type = \(key), Handler = \(String(describing: value))")
        }
    }

    func getHandlerForType(messageType: String) -> MessageHandler? {
        return handlers[messageType]
    }

    func canHandleMessage(_ message: AgentMessage) -> Bool {
        return handlers[message.type] != nil
    }

    static func replaceNewDidCommPrefixWithLegacyDidSov(messageType: String) -> String { //DEPRECATED
        let didSovPrefix = "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec"
        let didCommPrefix = "https://didcomm.org"

        if messageType.starts(with: didCommPrefix) {
            return messageType.replacingOccurrences(of: didCommPrefix, with: didSovPrefix)
        }

        return messageType
    }
}
