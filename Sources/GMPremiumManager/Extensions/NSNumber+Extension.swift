//
//  NSNumber+Extension.swift
//  GMPremiumManager
//
//  Created by Mert Serin on 2024-10-13.
//

import StoreKit

public extension NSNumber {
    func getPrice(for priceLocale: Locale?) -> String? {
        let formatter = SKProduct.formatter
        formatter.locale = priceLocale ?? .current

        return formatter.string(from: self)
    }
}
