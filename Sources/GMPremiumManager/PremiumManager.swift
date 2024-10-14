//
//  File.swift
//  GMPremiumManager
//
//  Created by Mert Serin on 2024-10-13.
//

import Adapty
import Combine
import SwiftUI

class PremiumManager: ObservableObject {

    enum Events {
        case onAdaptyActivate
        case onAdaptyUIActivated
        case onErrorActivate(Error)

        case onFetchPaywalls(PremiumManagerPaywall)

        case onLoadProfile(AdaptyProfile)
    }

    init(key: String, observerMode: Bool = false, idfaCollectionDisabled: Bool = false, customerUserId: String, ipAddressCollectionDisabled: Bool = false, implementation: GMPremiumManager) {

//        Adapty.delegate = self

        self.implementation = implementation
        self.implementation.configurationBuilder = Adapty.Configuration
            .Builder(withAPIKey: key)
            .with(observerMode: observerMode)
            .with(idfaCollectionDisabled: idfaCollectionDisabled)
            .with(customerUserId: customerUserId)
            .with(ipAddressCollectionDisabled: ipAddressCollectionDisabled)
    }

    private let implementation: GMPremiumManager

    @Published var isPremium = false
    var eventPassthrough: PassthroughSubject<Events, Never> = .init()

    func activate(appInstanceId: String?) async throws {
        try await implementation.activate(appInstanceId: appInstanceId)
    }

    func fetchAllPaywalls(for placements: [Placements]) async throws {
        try await implementation.fetchAllPaywalls(for: placements)
    }

    func getPaywall(with placement: Placements) -> PremiumManagerModel? {
        return implementation.paywalls[placement] ?? nil
    }

    private func fetchPaywall(for placement: Placements) async throws -> AdaptyPaywall {
        return try await implementation.fetchPaywall(for: placement)
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
                #warning("Send got premium event here")
            }
        } catch {
            #warning("Send error here")
        }
    }

    func fetchProfile() async throws -> AdaptyProfile {
        do {
            return try await implementation.fetchProfile()
        } catch {
            #warning("Send error here")
            throw error
        }
    }

    func restorePurchase() async throws {
        do {
            let profile = try await implementation.restorePurchases()
            let isPremium = checkSubscriptionStatus(profile: profile)
            self.isPremium = isPremium
            #warning("Send restore purchase event here")
        } catch {
            #warning("Send error here")
            throw error
        }
    }

    private func checkSubscriptionStatus(profile: AdaptyProfile) -> Bool {
        let accessLevels = implementation.checkSubscriptionStatus(profile: profile)
        return isPremium(with: accessLevels)
    }

    private func isPremium(with accessLevel: [String: AdaptyProfile.AccessLevel]) -> Bool {
        return accessLevel["premium"]?.isActive ?? false
    }

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

//    private func determineEvents(with product: AdaptyProduct) {
//        sendPurchaseFBSDK(product: product)
//
//        if let subscriptionPeriod = product.subscriptionPeriod, subscriptionPeriod.unit == .year {
//            sendSubcribeFBSDK(product: product)
//        }
//
//        if let introductoryOfferEligibility = product.introductoryDiscount, introductoryOfferEligibility.paymentMode == .freeTrial {
//            sendAddToCartFBSDK(product: product)
//        }
//    }

//    /// FBSDK events for every product purchase
//    private func sendPurchaseFBSDK(product: AdaptyProduct) {
//        AppEvents.shared.logPurchase(amount: Double(truncating: product.price as NSNumber), currency: product.currencyCode ?? "", parameters: [AppEvents.ParameterName.contentID : product.vendorProductId])
//    }
//
//    /// FBSDK events for trial
//    private func sendAddToCartFBSDK(product: AdaptyProduct) {
//        AppEvents.shared.logEvent(.addedToCart, parameters: [.contentID: product.vendorProductId])
//    }
//
//    /// FBSDK events for yearly subscriptions only
//    private func sendSubcribeFBSDK(product: AdaptyProduct) {
//        AppEvents.shared.logEvent(.subscribe, parameters: [.contentID: product.vendorProductId])
//    }
}

extension PremiumManager: AdaptyDelegate {
    func didLoadLatestProfile(_ profile: AdaptyProfile) {
        eventPassthrough.send(.onLoadProfile(profile))
    }
}
