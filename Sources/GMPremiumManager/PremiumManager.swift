//
//  File.swift
//  GMPremiumManager
//
//  Created by Mert Serin on 2024-10-13.
//

import Adapty
import AdaptyUI
import Combine
import SwiftUI

final public class PremiumManager: ObservableObject, @unchecked Sendable {

    public init(key: String, observerMode: Bool = false, idfaCollectionDisabled: Bool = false, customerUserId: String, ipAddressCollectionDisabled: Bool = false, implementation: GMPremiumManager) {

        self.implementation = implementation
        self.implementation.configurationBuilder = AdaptyConfiguration
            .builder(withAPIKey: key)
            .with(observerMode: observerMode)
            .with(idfaCollectionDisabled: idfaCollectionDisabled)
            .with(customerUserId: customerUserId)
            .with(ipAddressCollectionDisabled: ipAddressCollectionDisabled)
        Adapty.delegate = self
    }

    public static func configure(key: String, observerMode: Bool = false, idfaCollectionDisabled: Bool = false, customerUserId: String, ipAddressCollectionDisabled: Bool = false, implementation: GMPremiumManager) {
        if shared == nil {
            shared = PremiumManager(key: key, observerMode: observerMode, idfaCollectionDisabled: idfaCollectionDisabled, customerUserId: customerUserId, ipAddressCollectionDisabled: ipAddressCollectionDisabled, implementation: implementation)
        } else {
            fatalError("Premium Manager can be configured only once.")
        }
    }

    public static var shared: PremiumManager!
    private let implementation: GMPremiumManager

    @Published public var isPremium = false
    @Published public var activeAccessLevels: [String] = []
    public var eventPassthrough: PassthroughSubject<Events, Never> = .init()

    public func activate(appInstanceId: String?) async throws {
        if implementation.isActivated() {
            throw PremiumManagerError.alreadyActivated
        }
        do {
            try await implementation.activate(appInstanceId: appInstanceId)
            await MainActor.run {
                eventPassthrough.send(.onAdaptyActivate)
                eventPassthrough.send(.onAdaptyUIActivated)
            }
        } catch {
            await MainActor.run {
                eventPassthrough.send(.onErrorActivate(error))
            }
        }
    }

    public func fetchAllPaywalls(
        for placements: [any Placements],
        locale: String? = nil,
        flowConfigurationOptions: PremiumManagerFlowConfigurationOptions = .default
    ) async throws {
        try await implementation.fetchAllPaywalls(
            for: placements,
            locale: locale,
            flowConfigurationOptions: flowConfigurationOptions
        )
        await MainActor.run {
            eventPassthrough.send(.onFetchPaywalls(implementation.paywalls))
        }
    }

    public func getPaywall(with placement: any Placements) -> PremiumManagerModel? {
        return implementation.paywalls[placement.id] ?? nil
    }

    private func fetchPaywall(for placement: any Placements, locale: String? = nil) async throws -> AdaptyFlow {
        guard let paywall = try? await implementation.fetchPaywall(for: placement, locale: locale) else { throw PremiumManagerError.noRestore }
        return paywall
    }

    private func fetchPaywallConfiguration(
        for paywall: AdaptyFlow,
        locale: String? = nil,
        products: [AdaptyPaywallProduct]? = nil,
        flowConfigurationOptions: PremiumManagerFlowConfigurationOptions = .default
    ) async throws -> AdaptyUI.FlowConfiguration {
        return try await implementation.fetchPaywallConfiguration(
            for: paywall,
            locale: locale,
            products: products,
            flowConfigurationOptions: flowConfigurationOptions
        )
    }

    public func logPaywallOpen(for paywall: AdaptyFlow) async throws {
        try await implementation.logPaywallOpen(for: paywall)
    }

    public func purchase(with product: AdaptyPaywallProduct, source: String) async throws {
        do {
            let result = try await implementation.purchase(with: product)
            switch result {
            case .userCancelled:
                eventPassthrough.send(.onPurchaseFailed(PremiumManagerError.userCancelledPurchase))
                return
            case .pending:
                break
            case .success(let profile, let transaction):
                let isPremium = self.checkSubscriptionStatus(profile: profile)
                self.isPremium = isPremium
                self.activeAccessLevels = getActiveAccessLevels(in: profile)
                await MainActor.run {
                    eventPassthrough.send(.onPurchaseCompleted(product, isPremium, transaction))
                }
            }

        } catch {
            await MainActor.run {
                eventPassthrough.send(.onPurchaseFailed(error))
            }
            throw error
        }
    }

    public func fetchProfile() async throws -> AdaptyProfile {
        do {
            return try await implementation.fetchProfile()
        } catch {
            throw error
        }
    }

    public func restorePurchase() async throws {
        do {
            let profile = try await implementation.restorePurchases()
            let isPremium = checkSubscriptionStatus(profile: profile)
            self.isPremium = isPremium
            self.activeAccessLevels = getActiveAccessLevels(in: profile)
            await MainActor.run {
                if isPremium {
                    eventPassthrough.send(.onRestoreCompleted)
                } else {
                    eventPassthrough.send(.onRestoreFailed(PremiumManagerError.noRestore))
                }
            }
        } catch {
            await MainActor.run {
                eventPassthrough.send(.onRestoreFailed(error))
            }
            throw error
        }
    }

    public func checkSubscriptionStatus(profile: AdaptyProfile) -> Bool {
        let accessLevels = implementation.checkSubscriptionStatus(profile: profile)
        return isPremium(with: accessLevels)
    }

    /// Check if a specific access level is active
    /// - Parameter level: The access level identifier to check (e.g., "premium", "pro", "vip")
    /// - Parameter profile: The Adapty profile to check against
    /// - Returns: True if the specified access level exists and is active
    public func hasAccessLevel(_ level: String, in profile: AdaptyProfile) -> Bool {
        let accessLevels = implementation.checkSubscriptionStatus(profile: profile)
        return accessLevels[level]?.isActive ?? false
    }

    /// Check if a specific access level is active by fetching the latest profile
    /// - Parameter level: The access level identifier to check (e.g., "premium", "pro", "vip")
    /// - Returns: True if the specified access level exists and is active
    public func hasAccessLevel(_ level: String) async throws -> Bool {
        let profile = try await fetchProfile()
        return hasAccessLevel(level, in: profile)
    }

    /// Get all currently active access level identifiers from a profile
    /// - Parameter profile: The Adapty profile to check
    /// - Returns: Array of active access level identifiers
    public func getActiveAccessLevels(in profile: AdaptyProfile) -> [String] {
        let accessLevels = implementation.checkSubscriptionStatus(profile: profile)
        return accessLevels.filter { $0.value.isActive }.map { $0.key }
    }

    /// Get all currently active access level identifiers by fetching the latest profile
    /// - Returns: Array of active access level identifiers
    public func getActiveAccessLevels() async throws -> [String] {
        let profile = try await fetchProfile()
        return getActiveAccessLevels(in: profile)
    }

    /// Get detailed information about a specific access level
    /// - Parameter level: The access level identifier
    /// - Parameter profile: The Adapty profile to check
    /// - Returns: The access level details if it exists, nil otherwise
    public func getAccessLevel(_ level: String, in profile: AdaptyProfile) -> AdaptyProfile.AccessLevel? {
        let accessLevels = implementation.checkSubscriptionStatus(profile: profile)
        return accessLevels[level]
    }

    /// Get detailed information about a specific access level by fetching the latest profile
    /// - Parameter level: The access level identifier
    /// - Returns: The access level details if it exists, nil otherwise
    public func getAccessLevel(_ level: String) async throws -> AdaptyProfile.AccessLevel? {
        let profile = try await fetchProfile()
        return getAccessLevel(level, in: profile)
    }

    public func refreshPremiumState() async throws {
        let profile = try await fetchProfile()
        let isPremium = checkSubscriptionStatus(profile: profile)
        let newActiveAccessLevels = getActiveAccessLevels(in: profile)
        if self.isPremium != isPremium {
            await MainActor.run {
                eventPassthrough.send(.onChangePremiumState(oldValue: self.isPremium, newValue: isPremium))
            }
        }
        self.isPremium = isPremium
        self.activeAccessLevels = newActiveAccessLevels
    }

    private func isPremium(with accessLevel: [String: AdaptyProfile.AccessLevel]) -> Bool {
        return accessLevel["premium"]?.isActive == true || accessLevel["premium-plus"]?.isActive == true
    }
}

extension PremiumManager: AdaptyDelegate {
    public func didLoadLatestProfile(_ profile: AdaptyProfile) {
        eventPassthrough.send(.onLoadProfile(profile))
        isPremium = checkSubscriptionStatus(profile: profile)
        activeAccessLevels = getActiveAccessLevels(in: profile)
    }
}


// Helper for Facebook events
public extension PremiumManager {
    func shouldSendSubscribeEvent(for product: AdaptyProduct) -> Bool {
        if let subscriptionPeriod = product.subscriptionPeriod, subscriptionPeriod.unit == .year {
            return true
        }
        return false
    }

    func shouldSendAddToCartFBSDK(for product: AdaptyProduct) -> Bool {
        if let introductoryOfferEligibility = product.skProduct.subscription?.introductoryOffer,
           introductoryOfferEligibility.paymentMode == .freeTrial {
            return true
        }
        return false
    }
}

extension PremiumManager {
    public enum Events {
        case onAdaptyActivate
        case onAdaptyUIActivated
        case onErrorActivate(Error)

        case onFetchPaywalls(PremiumManagerPaywall)
        case onLoadProfile(AdaptyProfile)

        case onPurchaseCompleted(AdaptyProduct, Bool, any Sendable)
        case onPurchaseFailed(Error)

        case onChangePremiumState(oldValue: Bool, newValue: Bool)

        case onRestoreCompleted
        case onRestoreFailed(Error)

        // Adapty Paywall Builder Events
        case apbDidAppear(UIViewController)
        case apbDidDisappear(UIViewController)
        case apbCloseTapped(UIViewController)
        case apbOpenURL(URL)
        case apbCustomEvent(String)

        case apbProductSelect(AdaptyPaywallProduct)

        case apbDidPurchaseStart(AdaptyPaywallProduct)
        case apbDidPurchaseFinished(AdaptyPaywallProduct, AdaptyPurchaseResult)

        case apbDidFailedPurchase(AdaptyPaywallProduct, AdaptyError)
        case apbCancelPurchase(AdaptyPaywallProduct)

        case apbRestoreStart
        case apbRestoreSuccessful
        case apbNoRestoreAvailable
        case apbRestoreFailed(AdaptyError)

        case apbFailedRendering(AdaptyUIError)
        case apbFailedLoadingProducts(AdaptyError)
        case apbPartiallyLoadedProducts([String])
        case apbDidFinishWebPaymentNavigation(AdaptyPaywallProduct?, AdaptyError?)
        case apbDidReceiveAnalyticEvent(String, [String: any Sendable])
    }
}
