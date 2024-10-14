//
//  File.swift
//  GMPremiumManager
//
//  Created by Mert Serin on 2024-10-13.
//

import Foundation
import Adapty

final class GMPremiumManagerImpl: GMPremiumManager {
    var paywalls: PremiumManagerPaywall = [:]
    var configurationBuilder: Adapty.Configuration?

    func activate(appInstanceId: String?) async throws {
        guard let configurationBuilder else { return }
        do {
            try await Adapty.activate(with: configurationBuilder)

            if let appInstanceId = appInstanceId {
                let builder = AdaptyProfileParameters.Builder()
                    .with(firebaseAppInstanceId: appInstanceId)

                try? await Adapty.updateProfile(params: builder.build())
            }

            try await AdaptyUI.activate()
        } catch {
            #warning("Send error here")
            // TO-DO send error
        }
    }

    func fetchAllPaywalls(for placements: [Placements]) async throws {
        do {
            let fetchedPaywalls = try await withThrowingTaskGroup(of: (Placements, PremiumManagerModel?).self) { group in
                for placement in placements {
                    group.addTask {
                        if let paywall = try? await self.fetchPaywall(for: placement) {
                            let rcConfig = paywall.remoteConfig
                            let isPaywallBuilderEnabled = paywall.hasViewConfiguration
                            let products = try await Adapty.getPaywallProducts(paywall: paywall)
                            let configuration = isPaywallBuilderEnabled ? try? await self.fetchPaywallConfiguration(for: paywall) : nil

                            let model = PremiumManagerModel(paywall: paywall,
                                                            products: products,
                                                            rcConfig: rcConfig,
                                                            isPaywallBuilderEnabled: isPaywallBuilderEnabled,
                                                            configuration: configuration)

                            return (placement, model)
                        } else {
                            let paywall = try await self.fetchPaywall(for: .defaultPlacement)
                            let rcConfig = paywall.remoteConfig
                            let isPaywallBuilderEnabled = paywall.hasViewConfiguration
                            let products = try await Adapty.getPaywallProducts(paywall: paywall)
                            let configuration = try? await AdaptyUI.getViewConfiguration(forPaywall: paywall)

                            let model = PremiumManagerModel(paywall: paywall,
                                                            products: products,
                                                            rcConfig: rcConfig,
                                                            isPaywallBuilderEnabled: isPaywallBuilderEnabled,
                                                            configuration: configuration)
                            return (placement, model)
                        }
                    }
                }

                var results: [Placements: PremiumManagerModel] = [:]
                for try await (placement, model) in group {
                    if let model {
                        results[placement] = model
                    }
                }
                return results
            }

            self.paywalls = fetchedPaywalls
        } catch {
            throw PremiumManagerError.paywallFetchingError
        }
    }

    func getPaywall(with placement: Placements) -> PremiumManagerModel? {
        return paywalls[placement] ?? nil
    }

    func fetchPaywall(for placement: Placements) async throws -> AdaptyPaywall {
        try await withCheckedThrowingContinuation { continuation in
            Adapty.getPaywall(placementId: placement.rawValue) { result in
                switch result {
                case .success(let paywall):
                    continuation.resume(returning: paywall)
                case .failure(let error):
                    print("Mert123: ", error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchPaywallConfiguration(for paywall: AdaptyPaywall) async throws -> AdaptyUI.LocalizedViewConfiguration {
        try await withCheckedThrowingContinuation { continuation in
            AdaptyUI.getViewConfiguration(forPaywall: paywall, loadTimeout: 15, { result in
                switch result {
                case .success(let configuration):
                    continuation.resume(returning: configuration)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }

    func logPaywallOpen(for paywall: AdaptyPaywall) async throws {
        try await Adapty.logShowPaywall(paywall)
    }

    func purchase(with product: AdaptyPaywallProduct) async throws {
        do {
            try await Adapty.makePurchase(product: product)
        } catch {
            throw error
        }
    }

    func fetchProfile() async throws -> AdaptyProfile {
        return try await Adapty.getProfile()
    }

    func restorePurchases() async throws -> AdaptyProfile {
        return try await Adapty.restorePurchases()
    }

    func checkSubscriptionStatus(profile: AdaptyProfile) -> [String: AdaptyProfile.AccessLevel] {
        return profile.accessLevels
    }
}

