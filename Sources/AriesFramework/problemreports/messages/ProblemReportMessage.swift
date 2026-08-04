//
//  ProblemReportMessage.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation

public class ProblemReportMessage: AgentMessage {
    public let description: DescriptionOptions
    public let problemItems: [String]?
    public let whoRetries: WhoRetriesStatus?
    public let fixHint: FixHintOptions?
    public let impact: ImpactStatus?
    public let whereStatus: WhereStatus?
    public let noticedTime: String?
    public let trackingUri: String?
    public let escalationUri: String?

    class var type: String {
        return "https://didcomm.org/notification/2.0/problem-report"
    }


    private enum CodingKeys: String, CodingKey {
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

    init(
        description: DescriptionOptions,
        problemItems: [String]? = nil,
        whoRetries: WhoRetriesStatus? = nil,
        fixHint: FixHintOptions? = nil,
        impact: ImpactStatus? = nil,
        whereStatus: WhereStatus? = nil,
        noticedTime: String? = nil,
        trackingUri: String? = nil,
        escalationUri: String? = nil,
        id: String = UUID().uuidString
    ) {
        self.description = description
        self.problemItems = problemItems
        self.whoRetries = whoRetries
        self.fixHint = fixHint
        self.impact = impact
        self.whereStatus = whereStatus
        self.noticedTime = noticedTime
        self.trackingUri = trackingUri
        self.escalationUri = escalationUri
        super.init(id: id, type: Self.type)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.description = try container.decode(DescriptionOptions.self, forKey: .description)
        self.problemItems = try container.decodeIfPresent([String].self, forKey: .problemItems)
        self.whoRetries = try container.decodeIfPresent(WhoRetriesStatus.self, forKey: .whoRetries)
        self.fixHint = try container.decodeIfPresent(FixHintOptions.self, forKey: .fixHint)
        self.impact = try container.decodeIfPresent(ImpactStatus.self, forKey: .impact)
        self.whereStatus = try container.decodeIfPresent(WhereStatus.self, forKey: .whereStatus)
        self.noticedTime = try container.decodeIfPresent(String.self, forKey: .noticedTime)
        self.trackingUri = try container.decodeIfPresent(String.self, forKey: .trackingUri)
        self.escalationUri = try container.decodeIfPresent(String.self, forKey: .escalationUri)

        //superclass
        try super.init(from: decoder)
    }
}


public enum WhoRetriesStatus: String, Codable {
    case you = "YOU"
    case me = "ME"
    case both = "BOTH"
    case none = "NONE"
}

public enum ImpactStatus: String, Codable {
    case message = "MESSAGE"
    case thread = "THREAD"
    case connection = "CONNECTION"
}

public enum WhereStatus: String, Codable {
    case cloud = "CLOUD"
    case edge = "EDGE"
    case wire = "WIRE"
    case agency = "AGENCY"
}

public enum OtherStatus: String, Codable {
    case you = "YOU"
    case me = "ME"
    case other = "OTHER"
}
