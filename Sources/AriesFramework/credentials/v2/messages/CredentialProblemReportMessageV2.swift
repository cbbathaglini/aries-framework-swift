//
//  CredentialProblemReportMessageV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation

public class CredentialProblemReportMessageV2: ProblemReportMessage {
    
    public override class var type: String {
        return CredentialConstants.problemReportV2
    }
    
    enum CodingKeys: String, CodingKey {
        case description
        case problemItems = "problem_items"
        case whoRetries = "who_retries"
        case fixHint = "fix_hint"
        case impact
        case whereStatus = "where"
        case noticedTime = "noticed_time"
        case trackingUri = "tracking_uri"
        case escalationUri = "escalation_uri"
    }

    public init(
        description: DescriptionOptions,
        problemItems: [String]? = nil,
        whoRetries: WhoRetriesStatus? = nil,
        fixHint: FixHintOptions? = nil,
        impact: ImpactStatus? = nil,
        whereStatus: WhereStatus? = nil,
        noticedTime: String? = nil,
        trackingUri: String? = nil,
        escalationUri: String? = nil
    ) {
        super.init(
            description: description,
            problemItems: problemItems,
            whoRetries: whoRetries,
            fixHint: fixHint,
            impact: impact,
            whereStatus: whereStatus,
            noticedTime: noticedTime,
            trackingUri: trackingUri,
            escalationUri: escalationUri
        )
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let description = try container.decode(DescriptionOptions.self, forKey: .description)
        let problemItems = try container.decodeIfPresent([String].self, forKey: .problemItems)
        let whoRetries = try container.decodeIfPresent(WhoRetriesStatus.self, forKey: .whoRetries)
        let fixHint = try container.decodeIfPresent(FixHintOptions.self, forKey: .fixHint)
        let impact = try container.decodeIfPresent(ImpactStatus.self, forKey: .impact)
        let whereStatus = try container.decodeIfPresent(WhereStatus.self, forKey: .whereStatus)
        let noticedTime = try container.decodeIfPresent(String.self, forKey: .noticedTime)
        let trackingUri = try container.decodeIfPresent(String.self, forKey: .trackingUri)
        let escalationUri = try container.decodeIfPresent(String.self, forKey: .escalationUri)

        super.init(
            description: description,
            problemItems: problemItems,
            whoRetries: whoRetries,
            fixHint: fixHint,
            impact: impact,
            whereStatus: whereStatus,
            noticedTime: noticedTime,
            trackingUri: trackingUri,
            escalationUri: escalationUri
        )
    }
}
