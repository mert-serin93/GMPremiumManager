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
        let locale = self.sk2Product?.priceFormatStyle.locale

        switch subscriptionPeriodUnit {
        case .month:
            let price = (self.price as NSNumber).doubleValue / 4
            return (price as NSNumber).getPrice(for: locale)
        case .year:
            let numberOfWeeksInAYear = Calendar.current.maximumRange(of: .weekOfYear)?.upperBound ?? 52
            let price = (self.price as NSNumber).doubleValue / Double(numberOfWeeksInAYear)
            return (price as NSNumber).getPrice(for: locale)
        default: break
        }
        return (price as NSNumber).getPrice(for: locale)
    }
}
