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
    var configurationBuilder: AdaptyConfiguration.Builder? { get set }

    func activate(appInstanceId: String?) async throws
    func fetchAllPaywalls(for placements: [any Placements], locale: String?, flowConfigurationOptions: PremiumManagerFlowConfigurationOptions) async throws
    func getPaywall(with placement: any Placements) -> PremiumManagerModel?
    func fetchPaywall(for placement: any Placements, locale: String?) async throws -> AdaptyFlow?
    func fetchPaywallConfiguration(
        for paywall: AdaptyFlow,
        locale: String?,
        products: [AdaptyPaywallProduct]?,
        flowConfigurationOptions: PremiumManagerFlowConfigurationOptions
    ) async throws -> AdaptyUI.FlowConfiguration

    func purchase(with product: AdaptyPaywallProduct) async throws -> AdaptyPurchaseResult
    func restorePurchases() async throws -> AdaptyProfile

    func fetchProfile() async throws -> AdaptyProfile

    func logPaywallOpen(for paywall: AdaptyFlow) async throws

    func checkSubscriptionStatus(profile: AdaptyProfile) -> [String: AdaptyProfile.AccessLevel]

    func isActivated() -> Bool
}

public extension GMPremiumManager {
    func fetchAllPaywalls(
        for placements: [any Placements],
        locale: String? = nil
    ) async throws {
        try await fetchAllPaywalls(
            for: placements,
            locale: locale,
            flowConfigurationOptions: .default
        )
    }

    func fetchPaywallConfiguration(
        for paywall: AdaptyFlow,
        locale: String? = nil,
        products: [AdaptyPaywallProduct]? = nil
    ) async throws -> AdaptyUI.FlowConfiguration {
        try await fetchPaywallConfiguration(
            for: paywall,
            locale: locale,
            products: products,
            flowConfigurationOptions: .default
        )
    }
}
