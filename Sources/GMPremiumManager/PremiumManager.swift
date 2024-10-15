//
//  File.swift
//  GMPremiumManager
//
//  Created by Mert Serin on 2024-10-13.
//

import Adapty
import Combine
import SwiftUI

final public class PremiumManager: ObservableObject {

    init(key: String, observerMode: Bool = false, idfaCollectionDisabled: Bool = false, customerUserId: String, ipAddressCollectionDisabled: Bool = false, implementation: GMPremiumManager = GMPremiumManagerImpl()) {

        self.implementation = implementation
        self.implementation.configurationBuilder = Adapty.Configuration
            .Builder(withAPIKey: key)
            .with(observerMode: observerMode)
            .with(idfaCollectionDisabled: idfaCollectionDisabled)
            .with(customerUserId: customerUserId)
            .with(ipAddressCollectionDisabled: ipAddressCollectionDisabled)
        Adapty.delegate = self
    }

    static func configure(key: String, observerMode: Bool = false, idfaCollectionDisabled: Bool = false, customerUserId: String, ipAddressCollectionDisabled: Bool = false, implementation: GMPremiumManager = GMPremiumManagerImpl()) {
        if shared == nil {
            shared = PremiumManager(key: key, observerMode: observerMode, idfaCollectionDisabled: idfaCollectionDisabled, customerUserId: customerUserId, ipAddressCollectionDisabled: ipAddressCollectionDisabled)
        } else {
            fatalError("Premium Manager can be initailized only once.")
        }
    }

    static var shared: PremiumManager!
    private let implementation: GMPremiumManager

    @Published var isPremium = false
    var eventPassthrough: PassthroughSubject<Events, Never> = .init()

    func activate(appInstanceId: String?) async throws {
        try await implementation.activate(appInstanceId: appInstanceId)
    }

    func fetchAllPaywalls(for placements: [any Placements]) async throws {
        try await implementation.fetchAllPaywalls(for: placements)
    }

    func getPaywall(with placement: any Placements) -> PremiumManagerModel? {
        return implementation.paywalls[placement.id] ?? nil
    }

    private func fetchPaywall(for placement: any Placements) async throws -> AdaptyPaywall {
        guard let paywall = try? await implementation.fetchPaywall(for: placement) else { throw PremiumManagerError.noRestore }
        return paywall
    }

    private func fetchPaywallConfiguration(for paywall: AdaptyPaywall) async throws -> AdaptyUI.LocalizedViewConfiguration {
        return try await implementation.fetchPaywallConfiguration(for: paywall)
    }

    func logPaywallOpen(for paywall: AdaptyPaywall) async throws {
        try await implementation.logPaywallOpen(for: paywall)
    }

    func purchase(with product: AdaptyPaywallProduct, source: String) async throws {
        do {
            try await implementation.purchase(with: product)
            if let profile = try? await fetchProfile() {
                let isPremium = self.checkSubscriptionStatus(profile: profile)
                self.isPremium = isPremium
                eventPassthrough.send(.onPurchaseCompleted(product, isPremium))
            }
        } catch {
            eventPassthrough.send(.onPurchaseFailed(error))
        }
    }

    func fetchProfile() async throws -> AdaptyProfile {
        do {
            return try await implementation.fetchProfile()
        } catch {
            throw error
        }
    }

    func restorePurchase() async throws {
        do {
            let profile = try await implementation.restorePurchases()
            let isPremium = checkSubscriptionStatus(profile: profile)
            self.isPremium = isPremium
            eventPassthrough.send(.onRestoreCompleted)
        } catch {
            eventPassthrough.send(.onRestoreFailed(error))
        }
    }

    func checkSubscriptionStatus(profile: AdaptyProfile) -> Bool {
        let accessLevels = implementation.checkSubscriptionStatus(profile: profile)
        return isPremium(with: accessLevels)
    }

    private func isPremium(with accessLevel: [String: AdaptyProfile.AccessLevel]) -> Bool {
        return accessLevel["premium"]?.isActive ?? false
    }
}

extension PremiumManager: AdaptyDelegate {
    public func didLoadLatestProfile(_ profile: AdaptyProfile) {
        eventPassthrough.send(.onLoadProfile(profile))
        isPremium = checkSubscriptionStatus(profile: profile)
    }
}


// Helper for Facebook events
extension PremiumManager {
    func shouldSendSubscribeEvent(for product: AdaptyPaywallProduct) -> Bool {
        if let subscriptionPeriod = product.subscriptionPeriod, subscriptionPeriod.unit == .year {
            return true
        }
        return false
    }

    func shouldSendAddToCartFBSDK(for product: AdaptyPaywallProduct) -> Bool {
        if let introductoryOfferEligibility = product.introductoryDiscount, introductoryOfferEligibility.paymentMode == .freeTrial {
            return true
        }
        return false
    }
}

extension PremiumManager {
    enum Events {
        case onAdaptyActivate
        case onAdaptyUIActivated
        case onErrorActivate(Error)

        case onFetchPaywalls(PremiumManagerPaywall)
        case onLoadProfile(AdaptyProfile)

        case onPurchaseCompleted(AdaptyProduct, Bool)
        case onPurchaseFailed(Error)

        case onRestoreCompleted
        case onRestoreFailed(Error)

        // Adapty Paywall Builder Events
        case apbCloseTapped(UIViewController)
        case apbOpenURL(URL)
        case apbCustomEvent(String)

        case apbProductSelect(AdaptyPaywallProduct)

        case apbDidPurchaseStart(AdaptyPaywallProduct)
        case apbDidPurchaseFinished(AdaptyPaywallProduct, AdaptyPurchasedInfo)

        case apbDidFailedPurchase(AdaptyPaywallProduct, AdaptyError)
        case apbCancelPurchase(AdaptyPaywallProduct)

        case apbRestoreStart
        case apbRestoreSuccessful
        case apbNoRestoreAvailable
        case apbRestoreFailed(AdaptyError)

        case apbFailedRendering(AdaptyError)

    }
}
