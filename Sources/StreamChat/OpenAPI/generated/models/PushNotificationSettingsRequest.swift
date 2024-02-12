//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct PushNotificationSettingsRequest: Codable, Hashable {
    public var disabled: NullBoolRequest? = nil
    
    public var disabledUntil: NullTimeRequest? = nil
    
    public init(disabled: NullBoolRequest? = nil, disabledUntil: NullTimeRequest? = nil) {
        self.disabled = disabled
        
        self.disabledUntil = disabledUntil
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case disabled
        
        case disabledUntil = "disabled_until"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(disabled, forKey: .disabled)
        
        try container.encode(disabledUntil, forKey: .disabledUntil)
    }
}
