
import Foundation

public protocol AgentDelegate {
    func onConnectionStateChanged(connectionRecord: ConnectionRecord)
    func onMediationStateChanged(mediationRecord: MediationRecord)
    func onOutOfBandStateChanged(outOfBandRecord: OutOfBandRecord)
    func onCredentialStateChanged(credentialRecord: CredentialExchangeRecord)
    func onCredentialStateV2Changed(credentialRecord: CredentialExchangeRecord)
    func onProofStateChanged(proofRecord: ProofExchangeRecord)
    func onProofStateChangedV2(proofRecord: ProofExchangeRecord)
    func onProblemReportReceived(message: BaseProblemReportMessage)
    func onRevocationNotificationChanged(credentialExchangeRecord: CredentialExchangeRecord)
    func onRevocationNotificationV2Changed(credentialExchangeRecord: CredentialExchangeRecord)
    func onBasicMessageChanged(record: BasicMessageRecord)
}

// Default implementation of AgentDelegate
public extension AgentDelegate {
    func onConnectionStateChanged(connectionRecord: ConnectionRecord) {
    }

    func onMediationStateChanged(mediationRecord: MediationRecord) {
    }

    func onOutOfBandStateChanged(outOfBandRecord: OutOfBandRecord) {
    }

    func onCredentialStateChanged(credentialRecord: CredentialExchangeRecord) {
    }
    
    func onCredentialStateV2Changed(credentialRecord: CredentialExchangeRecord) {
    }

    func onProofStateChanged(proofRecord: ProofExchangeRecord) {
    }

    func onProofStateChangedV2(proofRecord: ProofExchangeRecord) {
    }

    
    func onProblemReportReceived(message: BaseProblemReportMessage) {
    }
    
    func onRevocationNotificationChanged(credentialExchangeRecord: CredentialExchangeRecord){
        
    }
    
    func onRevocationNotificationV2Changed(credentialExchangeRecord: CredentialExchangeRecord){
        
    }
    
    func onBasicMessageChanged(record: BasicMessageRecord){
        
    }
}
