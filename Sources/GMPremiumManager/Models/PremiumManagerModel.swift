//
//  PremiumManagerModel.swift
//  GMPremiumManager
//
//  Created by Mert Serin on 2024-10-13.
//

import Adapty
import AdaptyUI

typealias MappedProduct = AdaptyPaywallProduct
typealias PremiumManagerPaywall = [String: PremiumManagerModel]

struct PremiumManagerModel {
    let paywall: AdaptyPaywall
    let products: [AdaptyPaywallProduct]
    let rcConfig: AdaptyPaywall.RemoteConfig?
    let isPaywallBuilderEnabled: Bool
    let configuration: AdaptyUI.LocalizedViewConfiguration?
}
