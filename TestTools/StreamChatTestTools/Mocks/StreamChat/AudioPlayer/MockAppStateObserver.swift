//
//  MockAppStateObserver.swift
//  StreamChat
//
//  Created by Ilias Pavlidakis on 2/5/23.
//  Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public class MockAppStateObserver: AppStateObserving, Spy {
    public var recordedFunctions: [String] = []

    public private(set) var subscribeWasCalledWithSubscriber: AppStateObserverDelegate?
    public private(set) var unsubscribeWasCalledWithSubscriber: AppStateObserverDelegate?

    public init() {}

    public func subscribe(_ subscriber: AppStateObserverDelegate) {
        record()
        subscribeWasCalledWithSubscriber = subscriber
    }

    public func unsubscribe(_ subscriber: AppStateObserverDelegate) {
        record()
        unsubscribeWasCalledWithSubscriber = subscriber
    }
}
