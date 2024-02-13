//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessageResponse: Codable, Hashable {
    public var duration: String
    public var message: Message? = nil

    public init(duration: String, message: Message? = nil) {
        self.duration = duration
        self.message = message
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case message
    }
}
