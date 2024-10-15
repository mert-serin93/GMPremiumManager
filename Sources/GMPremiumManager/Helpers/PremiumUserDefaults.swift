//
//  PremiumUserDefaults.swift
//  GMPremiumManager
//
//  Created by Mert Serin on 2024-10-15.
//

import SwiftUI

final class PremiumUserDefaults {

    @AppStorage("savedPremium") private var savedPremium: Bool = false

    func setSavedPremium(with value: Bool) {
        savedPremium = value
    }

    func getSavedPremium() -> Bool { savedPremium }
}
