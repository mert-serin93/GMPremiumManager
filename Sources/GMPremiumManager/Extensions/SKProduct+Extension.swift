//
//  SKProduct+Extension.swift
//  GMPremiumManager
//
//  Created by Mert Serin on 2024-10-13.
//

import StoreKit

extension SKProduct: @retroactive Identifiable {
    public var id: String { return self.productIdentifier }
}
