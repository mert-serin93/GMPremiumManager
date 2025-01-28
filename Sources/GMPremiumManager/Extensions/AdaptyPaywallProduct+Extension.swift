//
//  AdaptyPaywallProduct+Extensions.swift
//  GMPremiumManager
//
//  Created by Mert Serin on 2024-10-13.
//

import Adapty
import Foundation

extension AdaptyPaywallProduct {
    public var id: String { return self.vendorProductId }

    var name: String {
        switch self.subscriptionPeriod?.unit {
        case .week, .day: return "Weekly"
        case .month: return "Monthly"
        case .year: return "Yearly"
        default: return ""
        }
    }
}

public extension AdaptyPaywallProduct {
    func weeklyFormattedPrice() -> String? {
        guard let subscriptionPeriodUnit = self.subscriptionPeriod?.unit else { return nil }

        switch subscriptionPeriodUnit {
        case .month:
            let price = (self.price as NSNumber).doubleValue / 4
            return (price as NSNumber).getPrice(for: self.sk1Product?.priceLocale)
        case .year:
            let price = (self.price as NSNumber).doubleValue / 52
            return (price as NSNumber).getPrice(for: self.sk1Product?.priceLocale)
        default: break
        }

        return (price as NSNumber).getPrice(for: self.sk1Product?.priceLocale)
    }
}
