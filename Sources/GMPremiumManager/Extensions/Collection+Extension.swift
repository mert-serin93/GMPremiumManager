//
//  File.swift
//  GMPremiumManager
//
//  Created by Mert Serin on 2024-10-13.
//

import Foundation
import StoreKit

extension Collection where Iterator.Element == SKProduct {
    func findProduct(by productID: String) -> SKProduct? {
        guard let first = self.filter({$0.id == productID}).first else { fatalError("Can not find \(productID)")}
        return first
    }
}

extension SKProduct {
    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    var isFree: Bool {
        price == 0.00
    }

    var localizedPrice: String? {
        guard !isFree else {
            return nil
        }

        let formatter = SKProduct.formatter
        formatter.locale = priceLocale

        return formatter.string(from: price)
    }
}
