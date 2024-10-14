//
//  SKProduct+Extension.swift
//  GMPremiumManager
//
//  Created by Mert Serin on 2024-10-13.
//

import StoreKit

extension SKProduct: Identifiable {
    public var id: String { return self.productIdentifier }
}
