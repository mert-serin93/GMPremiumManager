//
//  PremiumManagerError.swift
//  GMPremiumManager
//
//  Created by Mert Serin on 2024-10-13.
//

import Foundation

enum PremiumManagerError: LocalizedError {
    case noRestore
    case paywallFetchingError

    var errorDescription: String? {
        switch self {
        case .noRestore:
            return NSLocalizedString(
                "You have no subscription previously.",
                comment: ""
            )
        case .paywallFetchingError:
            return NSLocalizedString(
                "Something went wrong while fetching paywalls. Please try again.",
                comment: ""
            )
        }
    }
}
