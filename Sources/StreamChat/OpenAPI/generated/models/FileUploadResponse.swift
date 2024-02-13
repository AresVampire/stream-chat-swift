//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct FileUploadResponse: Codable, Hashable {
    public var duration: String
    public var file: String? = nil
    public var thumbUrl: String? = nil

    public init(duration: String, file: String? = nil, thumbUrl: String? = nil) {
        self.duration = duration
        self.file = file
        self.thumbUrl = thumbUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case file
        case thumbUrl = "thumb_url"
    }
}
