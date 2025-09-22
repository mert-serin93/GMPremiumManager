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
    public let paywall: AdaptyPaywall
    public let products: [AdaptyPaywallProduct]
    public let rcConfig: AdaptyRemoteConfig?
    public let isPaywallBuilderEnabled: Bool
    public let configuration: AdaptyUI.PaywallConfiguration?
}
