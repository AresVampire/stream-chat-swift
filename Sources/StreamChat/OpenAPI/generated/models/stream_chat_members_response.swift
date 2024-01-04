//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMembersResponse: Codable, Hashable {
    public var duration: String
    
    public var members: [StreamChatChannelMember?]
    
    public init(duration: String, members: [StreamChatChannelMember?]) {
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
