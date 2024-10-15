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
    var configurationBuilder: Adapty.Configuration.Builder?

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

    func fetchAllPaywalls(for placements: [any Placements]) async throws {
        do {
            let fetchedPaywalls = try await withThrowingTaskGroup(of: (String, PremiumManagerModel?).self) { group in
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

                            return (placement.id, model)
                        }
                        return (placement.id, nil)
                    }
                }

                var results: [String: PremiumManagerModel] = [:]
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

    func getPaywall(with placement: any Placements) -> PremiumManagerModel? {
        return paywalls[placement.id] ?? nil
    }

    func fetchPaywall(for placement: any Placements) async throws -> AdaptyPaywall? {
        try? await withCheckedThrowingContinuation { continuation in
            Adapty.getPaywall(placementId: placement.id) { result in
                switch result {
                case .success(let paywall):
//                    continuation.resume(returning: paywall)
                    break
                case .failure(let error):
                    continuation.resume(throwing: error)
                    break
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

