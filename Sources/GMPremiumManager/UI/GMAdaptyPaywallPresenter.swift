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

final public class GMAdaptyPaywallPresenter: NSObject {

    public static let shared = GMAdaptyPaywallPresenter()

    /// Access PremiumManagerModel, will be used for logPaywall function
    public func getPaywallModel(with placement: any Placements) throws -> PremiumManagerModel {
        guard let model = PremiumManager.shared.getPaywall(with: placement) else { throw PaywallPresenterError.noPaywall }
        return model
    }

    /// Access Adapty's Flow Builder or Paywall Builder flow as SwiftUI View.
    @MainActor
    public func getPaywallSwiftUI(from model: PremiumManagerModel) throws -> some View {
        let viewController = try getPaywallViewController(from: model)
        return viewController.toSwiftUI()
    }

    /// Access Adapty's Flow Builder or Paywall Builder flow.
    @MainActor
    public func getPaywallViewController(from model: PremiumManagerModel) throws -> UIViewController {

        if !model.isPaywallBuilderEnabled { throw PaywallPresenterError.noDynamicPaywall }
        guard let configuration = model.configuration else { throw PaywallPresenterError.noPaywallConfiguration }

        guard let vc = try? AdaptyUI.flowController(with: configuration, delegate: self) else { throw PaywallPresenterError.noDynamicPaywall }
        return vc
    }

    public func logPaywall(with paywall: AdaptyFlow) {
        Task {
            try await PremiumManager.shared.logPaywallOpen(for: paywall)
        }
    }
}

extension GMAdaptyPaywallPresenter: AdaptyFlowControllerDelegate {

    public func flowControllerDidAppear(_ controller: AdaptyFlowController) {
        PremiumManager.shared.eventPassthrough.send(.apbDidAppear(controller))
    }

    public func flowControllerDidDisappear(_ controller: AdaptyFlowController) {
        PremiumManager.shared.eventPassthrough.send(.apbDidDisappear(controller))
    }

    public func flowController(
        _ controller: AdaptyFlowController,
        didPerform action: AdaptyUI.Action
    ) {
        switch action {
        case .close:
            PremiumManager.shared.eventPassthrough.send(.apbCloseTapped(controller))
        case .openURL(let url, _):
            PremiumManager.shared.eventPassthrough.send(.apbOpenURL(url))
        case .custom(let customEventID):
            PremiumManager.shared.eventPassthrough.send(.apbCustomEvent(customEventID))
        }
    }

    public func flowController(
        _ controller: AdaptyFlowController,
        didSelectProduct product: AdaptyPaywallProduct
    ) {
        PremiumManager.shared.eventPassthrough.send(.apbProductSelect(product))
    }

    public func flowController(
        _ controller: AdaptyFlowController,
        didStartPurchase product: AdaptyPaywallProduct
    ) {
        PremiumManager.shared.eventPassthrough.send(.apbDidPurchaseStart(product))
    }

    public func flowController(_ controller: AdaptyFlowController, didFinishPurchase product: AdaptyPaywallProduct, purchaseResult: AdaptyPurchaseResult) {
        switch purchaseResult {
        case .userCancelled:
            PremiumManager.shared.eventPassthrough.send(.apbCancelPurchase(product))
        case .pending:
            break
        case .success:
            controller.dismiss(animated: true)
            Task {
                let profile = try await PremiumManager.shared.fetchProfile()
                PremiumManager.shared.didLoadLatestProfile(profile)
                await MainActor.run {
                    PremiumManager.shared.eventPassthrough.send(.apbDidPurchaseFinished(product, purchaseResult))
                }
            }
        }
    }

    public func flowController(
        _ controller: AdaptyFlowController,
        didFailPurchase product: AdaptyPaywallProduct,
        error: AdaptyError
    ) {
        PremiumManager.shared.eventPassthrough.send(.apbDidFailedPurchase(product, error))

    }

    public func flowControllerDidStartRestore(_ controller: AdaptyFlowController) {
        PremiumManager.shared.eventPassthrough.send(.apbRestoreStart)
    }

    public func flowController(
        _ controller: AdaptyFlowController,
        didFinishRestoreWith profile: AdaptyProfile
    ) {
        let isPremium = PremiumManager.shared.checkSubscriptionStatus(profile: profile)
        if isPremium {
            PremiumManager.shared.eventPassthrough.send(.apbRestoreSuccessful)
        } else {
            PremiumManager.shared.eventPassthrough.send(.apbNoRestoreAvailable)
        }
    }


    public func flowController(
        _ controller: AdaptyFlowController,
        didFailRestoreWith error: AdaptyError
    ) {
        PremiumManager.shared.eventPassthrough.send(.apbRestoreFailed(error))
    }

    public func flowController(
        _ controller: AdaptyFlowController,
        didReceiveError error: AdaptyUIError
    ) {
        PremiumManager.shared.eventPassthrough.send(.apbFailedRendering(error))
    }


    public func flowController(_ controller: AdaptyFlowController, didFailLoadingProductsWith error: AdaptyError) -> Bool {
        PremiumManager.shared.eventPassthrough.send(.apbFailedLoadingProducts(error))
        return true
    }
    
    public func flowController(_ controller: AdaptyFlowController, didPartiallyLoadProducts failedIds: [String]) {
        PremiumManager.shared.eventPassthrough.send(.apbPartiallyLoadedProducts(failedIds))
    }

    public func flowController(
        _ controller: AdaptyFlowController,
        didFinishWebPaymentNavigation product: AdaptyPaywallProduct?,
        error: AdaptyError?
    ) {
        PremiumManager.shared.eventPassthrough.send(.apbDidFinishWebPaymentNavigation(product, error))
    }

    public func flowController(
        _ controller: AdaptyFlowController,
        didReceiveAnalyticEvent name: String,
        params: [String: any Sendable]
    ) {
        PremiumManager.shared.eventPassthrough.send(.apbDidReceiveAnalyticEvent(name, params))
    }
}
