//
//  GMPremiumManager.swift
//  GMPremiumManager
//
//  Created by Mert Serin on 2024-10-13.
//
import Adapty
import AdaptyUI

public protocol GMPremiumManager: AnyObject {
    // Public API
    var paywalls: PremiumManagerPaywall { get set}
    var configurationBuilder: Adapty.Configuration.Builder? { get set }

    func activate(appInstanceId: String?) async throws
    func fetchAllPaywalls(for placements: [any Placements]) async throws
    func getPaywall(with placement: any Placements) -> PremiumManagerModel?
    func fetchPaywall(for placement: any Placements) async throws -> AdaptyPaywall?
    func fetchPaywallConfiguration(for paywall: AdaptyPaywall) async throws -> AdaptyUI.LocalizedViewConfiguration

    func purchase(with product: AdaptyPaywallProduct) async throws
    func restorePurchases() async throws -> AdaptyProfile

    func fetchProfile() async throws -> AdaptyProfile

    func logPaywallOpen(for paywall: AdaptyPaywall) async throws

    func checkSubscriptionStatus(profile: AdaptyProfile) -> [String: AdaptyProfile.AccessLevel]
}
