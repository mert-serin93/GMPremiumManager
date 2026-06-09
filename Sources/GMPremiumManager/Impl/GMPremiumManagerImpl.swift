//
//  File.swift
//  GMPremiumManager
//
//  Created by Mert Serin on 2024-10-13.
//

import Foundation
import Adapty
import AdaptyUI

final public class GMPremiumManagerImpl: GMPremiumManager {
    public var paywalls: PremiumManagerPaywall = [:]
    public var configurationBuilder: AdaptyConfiguration.Builder?

    private var isAdaptyActivated: Bool = false

    public init() {

    }

    public func activate(appInstanceId: String?) async throws {
        guard let configurationBuilder else { return }
        do {
            try await Adapty.activate(with: configurationBuilder.build())

            if let appInstanceId = appInstanceId {
                try await Adapty.setIntegrationIdentifier(.firebaseAppInstanceId(appInstanceId))
            }

            try await AdaptyUI.activate()
            self.isAdaptyActivated = true
        } catch {
            throw error
        }
    }

    public func fetchAllPaywalls(
        for placements: [any Placements],
        locale: String? = nil,
        flowConfigurationOptions: PremiumManagerFlowConfigurationOptions = .default
    ) async throws {
        do {
            let fetchedPaywalls = try await withThrowingTaskGroup(of: (String, PremiumManagerModel?).self) { group in
                for placement in placements {
                    group.addTask {
                        if let paywall = try? await self.fetchPaywall(for: placement, locale: locale) {
                            let isPaywallBuilderEnabled = paywall.hasViewConfiguration
                            let products = try await Adapty.getPaywallProducts(flow: paywall)
                            let configuration = isPaywallBuilderEnabled ? try? await self.fetchPaywallConfiguration(
                                for: paywall,
                                locale: locale,
                                products: products,
                                flowConfigurationOptions: flowConfigurationOptions
                            ) : nil

                            let model = PremiumManagerModel(paywall: paywall,
                                                            products: products,
                                                            rcConfigs: paywall.remoteConfigs,
                                                            locale: locale,
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

    public func getPaywall(with placement: any Placements) -> PremiumManagerModel? {
        return paywalls[placement.id] ?? nil
    }

    public func fetchPaywall(for placement: any Placements, locale: String? = nil) async throws -> AdaptyFlow? {
        try await Adapty.getFlow(placementId: placement.id)
    }

    public func fetchPaywallConfiguration(
        for paywall: AdaptyFlow,
        locale: String? = nil,
        products: [AdaptyPaywallProduct]? = nil,
        flowConfigurationOptions: PremiumManagerFlowConfigurationOptions = .default
    ) async throws -> AdaptyUI.FlowConfiguration {
        try await AdaptyUI.getFlowConfiguration(
            forFlow: paywall,
            locale: locale,
            loadTimeout: flowConfigurationOptions.loadTimeout,
            products: products,
            observerModeResolver: flowConfigurationOptions.observerModeResolver,
            tagResolver: flowConfigurationOptions.tagResolver,
            timerResolver: flowConfigurationOptions.timerResolver,
            assetsResolver: flowConfigurationOptions.assetsResolver,
            systemRequestsHandler: flowConfigurationOptions.systemRequestsHandler
        )
    }

    public func logPaywallOpen(for paywall: AdaptyFlow) async throws {
        try await Adapty.logShowFlow(paywall)
    }

    public func purchase(with product: AdaptyPaywallProduct) async throws -> AdaptyPurchaseResult {
        do {
            return try await Adapty.makePurchase(product: product)
        } catch {
            throw error
        }
    }

    public func fetchProfile() async throws -> AdaptyProfile {
        return try await Adapty.getProfile()
    }

    public func restorePurchases() async throws -> AdaptyProfile {
        return try await Adapty.restorePurchases()
    }

    public func checkSubscriptionStatus(profile: AdaptyProfile) -> [String: AdaptyProfile.AccessLevel] {
        return profile.accessLevels
    }

    public func isActivated() -> Bool {
        return isAdaptyActivated
    }
}
