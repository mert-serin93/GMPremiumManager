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

    public init(key: String, observerMode: Bool = false, idfaCollectionDisabled: Bool = false, customerUserId: String, ipAddressCollectionDisabled: Bool = false, implementation: GMPremiumManager) {

        self.implementation = implementation
        self.implementation.configurationBuilder = Adapty.Configuration
            .Builder(withAPIKey: key)
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

    public func fetchAllPaywalls(for placements: [any Placements]) async throws {
        try await implementation.fetchAllPaywalls(for: placements)
        await MainActor.run {
            eventPassthrough.send(.onFetchPaywalls(implementation.paywalls))
        }
    }

    public func getPaywall(with placement: any Placements) -> PremiumManagerModel? {
        return implementation.paywalls[placement.id] ?? nil
    }

    private func fetchPaywall(for placement: any Placements) async throws -> AdaptyPaywall {
        guard let paywall = try? await implementation.fetchPaywall(for: placement) else { throw PremiumManagerError.noRestore }
        return paywall
    }

    private func fetchPaywallConfiguration(for paywall: AdaptyPaywall) async throws -> AdaptyUI.LocalizedViewConfiguration {
        return try await implementation.fetchPaywallConfiguration(for: paywall)
    }

    public func logPaywallOpen(for paywall: AdaptyPaywall) async throws {
        try await implementation.logPaywallOpen(for: paywall)
    }

    public func purchase(with product: AdaptyPaywallProduct, source: String) async throws {
        do {
            try await implementation.purchase(with: product)
            if let profile = try? await fetchProfile() {
                let isPremium = self.checkSubscriptionStatus(profile: profile)
                self.isPremium = isPremium
                await MainActor.run {
                    eventPassthrough.send(.onPurchaseCompleted(product, isPremium))
                }
            }
        } catch {
            await MainActor.run {
                eventPassthrough.send(.onPurchaseFailed(error))
            }
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
            await MainActor.run {
                eventPassthrough.send(.onRestoreCompleted)
            }
        } catch {
            await MainActor.run {
                eventPassthrough.send(.onRestoreFailed(error))
            }
        }
    }

    public func checkSubscriptionStatus(profile: AdaptyProfile) -> Bool {
        let accessLevels = implementation.checkSubscriptionStatus(profile: profile)
        return isPremium(with: accessLevels)
    }

    public func refreshPremiumState() async throws {
        let profile = try await fetchProfile()
        let isPremium = checkSubscriptionStatus(profile: profile)
        if self.isPremium != isPremium {
            await MainActor.run {
                eventPassthrough.send(.onChangePremiumState(oldValue: self.isPremium, newValue: isPremium))
            }
        }
        self.isPremium = isPremium
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
public extension PremiumManager {
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
    public enum Events {
        case onAdaptyActivate
        case onAdaptyUIActivated
        case onErrorActivate(Error)

        case onFetchPaywalls(PremiumManagerPaywall)
        case onLoadProfile(AdaptyProfile)

        case onPurchaseCompleted(AdaptyProduct, Bool)
        case onPurchaseFailed(Error)

        case onChangePremiumState(oldValue: Bool, newValue: Bool)

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
