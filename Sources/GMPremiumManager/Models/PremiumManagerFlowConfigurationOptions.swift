//
//  PremiumManagerFlowConfigurationOptions.swift
//  GMPremiumManager
//
//  Created by Mert Serin on 2026-06-09.
//

import AdaptyUI
import Foundation

public struct PremiumManagerFlowConfigurationOptions: Sendable {
    public static let `default` = PremiumManagerFlowConfigurationOptions()

    public let loadTimeout: TimeInterval?
    public let observerModeResolver: AdaptyObserverModeResolver?
    public let tagResolver: AdaptyTagResolver?
    public let timerResolver: AdaptyTimerResolver?
    public let assetsResolver: AdaptyAssetsResolver?
    public let systemRequestsHandler: AdaptySystemRequestsHandler?

    public init(
        loadTimeout: TimeInterval? = 15,
        observerModeResolver: AdaptyObserverModeResolver? = nil,
        tagResolver: AdaptyTagResolver? = nil,
        timerResolver: AdaptyTimerResolver? = nil,
        assetsResolver: AdaptyAssetsResolver? = nil,
        systemRequestsHandler: AdaptySystemRequestsHandler? = nil
    ) {
        self.loadTimeout = loadTimeout
        self.observerModeResolver = observerModeResolver
        self.tagResolver = tagResolver
        self.timerResolver = timerResolver
        self.assetsResolver = assetsResolver
        self.systemRequestsHandler = systemRequestsHandler
    }
}
