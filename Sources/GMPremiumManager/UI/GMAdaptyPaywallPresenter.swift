//
//  GMAdaptyPaywallPresenter.swift
//  GMPremiumManager
//
//  Created by Mert Serin on 2024-10-15.
//

import Adapty
import AdaptyUI
import SwiftUI

enum PaywallPresenterError: Error {
    case noPaywall
    case noPaywallConfiguration
    case noDynamicPaywall
}

final class GMAdaptyPaywallPresenter: NSObject {

    /// Access PremiumManagerModel, will be used for logPaywall function
    func getPaywallModel(with placement: any Placements) throws -> PremiumManagerModel {
        guard let model = PremiumManager.shared.getPaywall(with: placement) else { throw PaywallPresenterError.noPaywall }
        return model
    }

    /// Access Adapty's Paywall Builder paywall as SwiftUI View, logPaywall needs to call seperately
    func getPaywallSwiftUI(from model: PremiumManagerModel) throws -> some View {
        let viewController = try getPaywallViewController(from: model)
        return viewController.toSwiftUI()
    }

    /// Access Adapty's Paywall Builder paywall, logPaywall needs to call seperately
    func getPaywallViewController(from model: PremiumManagerModel) throws -> UIViewController {

        if !model.isPaywallBuilderEnabled { throw PaywallPresenterError.noDynamicPaywall }
        guard let configuration = model.configuration else { throw PaywallPresenterError.noPaywallConfiguration }

        guard let vc = try? AdaptyUI.paywallController(for: model.paywall, viewConfiguration: configuration, delegate: self) else { throw PaywallPresenterError.noDynamicPaywall }
        return vc
    }

    func logPaywall(with paywall: AdaptyPaywall) {
        Task {
            try await PremiumManager.shared.logPaywallOpen(for: paywall)
        }
    }
}

extension GMAdaptyPaywallPresenter: AdaptyPaywallControllerDelegate {

    func paywallController(
        _ controller: AdaptyPaywallController,
        didPerform action: AdaptyUI.Action
    ) {
        switch action {
        case .close:
            PremiumManager.shared.eventPassthrough.send(.apbCloseTapped(controller))
        case .openURL(let url):
            PremiumManager.shared.eventPassthrough.send(.apbOpenURL(url))
        case .custom(let customEventID):
            PremiumManager.shared.eventPassthrough.send(.apbCustomEvent(customEventID))
        }
    }

    func paywallController(
        _ controller: AdaptyPaywallController,
        didSelectProduct product: AdaptyPaywallProduct
    ) {
        PremiumManager.shared.eventPassthrough.send(.apbProductSelect(product))
    }

    func paywallController(
        _ controller: AdaptyPaywallController,
        didStartPurchase product: AdaptyPaywallProduct
    ) {
        PremiumManager.shared.eventPassthrough.send(.apbDidPurchaseStart(product))
    }

    func paywallController(
        _ controller: AdaptyPaywallController,
        didFinishPurchase product: AdaptyPaywallProduct,
        purchasedInfo: AdaptyPurchasedInfo
    ) {
        Task {
            let profile = try await PremiumManager.shared.fetchProfile()
            PremiumManager.shared.didLoadLatestProfile(profile)
            await MainActor.run {
                PremiumManager.shared.eventPassthrough.send(.apbDidPurchaseFinished(product, purchasedInfo))
            }
        }
    }

    func paywallController(
        _ controller: AdaptyPaywallController,
        didFailPurchase product: AdaptyPaywallProduct,
        error: AdaptyError
    ) {
        PremiumManager.shared.eventPassthrough.send(.apbDidFailedPurchase(product, error))

    }

    func paywallController(
        _ controller: AdaptyPaywallController,
        didCancelPurchase product: AdaptyPaywallProduct
    ) {
        PremiumManager.shared.eventPassthrough.send(.apbCancelPurchase(product))
    }

    func paywallControllerDidStartRestore(_ controller: AdaptyPaywallController) {
        PremiumManager.shared.eventPassthrough.send(.apbRestoreStart)
    }

    func paywallController(
        _ controller: AdaptyPaywallController,
        didFinishRestoreWith profile: AdaptyProfile
    ) {
        let isPremium = PremiumManager.shared.checkSubscriptionStatus(profile: profile)
        if isPremium {
            PremiumManager.shared.eventPassthrough.send(.apbRestoreSuccessful)
        } else {
            PremiumManager.shared.eventPassthrough.send(.apbNoRestoreAvailable)
        }
    }


    func paywallController(
        _ controller: AdaptyPaywallController,
        didFailRestoreWith error: AdaptyError
    ) {
        PremiumManager.shared.eventPassthrough.send(.apbRestoreFailed(error))
    }

    func paywallController(
        _ controller: AdaptyPaywallController,
        didFailRenderingWith error: AdaptyError
    ) {
        PremiumManager.shared.eventPassthrough.send(.apbFailedRendering(error))
    }


    func paywallController(_ controller: AdaptyPaywallController, didFailLoadingProductsWith error: AdaptyError) -> Bool {
        return true
    }
}