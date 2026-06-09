//
//  PremiumManagerModel.swift
//  GMPremiumManager
//
//  Created by Mert Serin on 2024-10-13.
//

import Adapty
import AdaptyUI

public typealias MappedProduct = AdaptyPaywallProduct
public typealias PremiumManagerPaywall = [String: PremiumManagerModel]

public struct PremiumManagerModel {
    public let paywall: AdaptyFlow
    public let products: [AdaptyPaywallProduct]
    public let rcConfigs: [AdaptyRemoteConfig]
    public let rcConfig: AdaptyRemoteConfig?
    public let isPaywallBuilderEnabled: Bool
    public let configuration: AdaptyUI.FlowConfiguration?

    public init(
        paywall: AdaptyFlow,
        products: [AdaptyPaywallProduct],
        rcConfigs: [AdaptyRemoteConfig],
        locale: String? = nil,
        isPaywallBuilderEnabled: Bool,
        configuration: AdaptyUI.FlowConfiguration?
    ) {
        self.paywall = paywall
        self.products = products
        self.rcConfigs = rcConfigs
        self.rcConfig = Self.remoteConfig(in: rcConfigs, matching: locale)
        self.isPaywallBuilderEnabled = isPaywallBuilderEnabled
        self.configuration = configuration
    }

    public var flow: AdaptyFlow {
        paywall
    }

    public func remoteConfig(for locale: String?) -> AdaptyRemoteConfig? {
        Self.remoteConfig(in: rcConfigs, matching: locale)
    }

    private static func remoteConfig(in remoteConfigs: [AdaptyRemoteConfig], matching locale: String?) -> AdaptyRemoteConfig? {
        guard let locale else { return remoteConfigs.first }
        return remoteConfigs.first { $0.locale == locale } ?? remoteConfigs.first
    }
}
