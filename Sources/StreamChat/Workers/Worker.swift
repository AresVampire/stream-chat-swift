//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

typealias WorkerBuilder = (
    _ database: DatabaseContainer,
    _ apiClient: APIClient
) -> Worker

class Worker {
    let database: DatabaseContainer
    let apiClient: APIClient
    let defaultAPI: DefaultAPI
    
    public init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
        // TODO: fix this.
        defaultAPI = DefaultAPI(
            basePath: "TODO",
            transport: URLSessionTransport(urlSession: .shared),
            middlewares: []
        )
    }

    public init(database: DatabaseContainer, apiClient: APIClient, defaultAPI: DefaultAPI? = nil) {
        self.database = database
        self.apiClient = apiClient
        // TODO: fix this.
        self.defaultAPI = defaultAPI ?? DefaultAPI(
            basePath: "TODO",
            transport: URLSessionTransport(urlSession: .shared),
            middlewares: []
        )
    }
}
