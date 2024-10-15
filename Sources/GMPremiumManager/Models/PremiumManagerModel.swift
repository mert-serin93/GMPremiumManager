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
    let paywall: AdaptyPaywall
    let products: [AdaptyPaywallProduct]
    let rcConfig: AdaptyPaywall.RemoteConfig?
    let isPaywallBuilderEnabled: Bool
    let configuration: AdaptyUI.LocalizedViewConfiguration?
}
