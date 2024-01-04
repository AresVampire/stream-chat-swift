//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateCallMembersResponse: Codable, Hashable {
    public var duration: String
    
    public var members: [StreamChatMemberResponse]
    
    public init(duration: String, members: [StreamChatMemberResponse]) {
        self.duration = duration
        
        self.members = members
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case members
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(members, forKey: .members)
    }
}
