//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatXiaomiConfigFields: Codable, Hashable {
    public var enabled: Bool
    
    public var packageName: String? = nil
    
    public var secret: String? = nil
    
    public init(enabled: Bool, packageName: String? = nil, secret: String? = nil) {
        self.enabled = enabled
        
        self.packageName = packageName
        
        self.secret = secret
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        
        case packageName = "package_name"
        
        case secret
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(enabled, forKey: .enabled)
        
        try container.encode(packageName, forKey: .packageName)
        
        try container.encode(secret, forKey: .secret)
    }
}
