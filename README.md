# 1. Configure


PremiumManager needs to be configured on AppDelegate or SwiftUI's App init, only once. For customerUserId you need to use the unique identifier that you created once user installed the app. If you are using something from Firebase ID or AppsFlyer ID you can also pass this one here.


`PremiumManager.configure(key: <YOUR_ADAPTY_KEY>, observerMode: false, idfaCollectionDisabled: false, customerUserId: <Custom_user_id that you use to identify user> ipAddressCollectionDisabled: false, implementation: GMPremiumManagerImpl())`


# 2. Activation and Fetching Paywalls


Once PremiumManager is configured you need to activate and fetch all paywalls for the active placements. Adapty doesn't have any build in function to fetch active placements so we need to create an enum that has all the placements that's been created on Adapty. (you can find AdaptyPlacements enum on example picture)
After you created this enum you can activate the Adapty and fetch all the paywalls for placements.

```
Task {
      do {
        try await PremiumManager.shared.activate(appInstanceId: Analytics.appInstanceID())
        try await PremiumManager.shared.fetchAllPaywalls(for: AdaptyPlacements.allCases)

      } catch {
        print("premium manager error: ", error)
      }
}
```



This will fetch all the paywalls and keep it in the dictionary for later uses.


# 3. Listening Premium Manager events


PremiumManager has eventPassthrough  variable that publishes all the changes that happens in Adapty SDK, you can find the full event list on PremiumManager's Event enum. It's a combine publisher so for listening changes to show error or show success pop-up you need to listen wherever it's needed. For potential memory leaks you need to make sure that it's removed if you are listening from ViewController.
You can listen changes like this:

```
PremiumManager.shared.eventPassthrough.sink {[weak self] output in
      guard let self else { return }
      // Do what you want to do with output in switch case
    }.store(in: &storage)
```



the ones start with APB prefix is for Adapty Paywall Builder events.


# 4. Accessing Paywall


Once you fetched all the paywalls, you can access any of the paywall with:

```
PremiumManager.shared.getPaywall(with: placement that you created on AdaptyPlacements)
```



In return you'll get a PremiumManagerModel that contains all the information about product, if paywall builder is enabled, Remote Config for this particular paywall. You can use these products and show it in custom paywall or you can use paywall builder's UI.


# 5. Showing Paywall Builder's Paywall


After you access paywall with:
guard let paywall = PremiumManager.shared.getPaywall(with: AdaptyPlacements.generic) else { return }
you can check if the paywall builder is enabled by

```
if paywall.isPaywallBuilderEnabled {
      do {
        let viewController = try GMAdaptyPaywallPresenter.shared.getPaywallViewController(from: paywall)
        viewModel.sceneManager.present(viewController: viewController)
      } catch {
        viewModel.isPaywallPresented = true
      }
    }
```


GMAdaptyPaywallPresenter has two functions getPaywallViewController and getPaywallSwiftUI to support both UIKit and SwiftUI. All the events that is done on Adapty Paywall will send events with APB Prefix(you can find the full list on Events Enum)


# 6. Purchase


PremiumManager has a function name purchase to start purchase process. Based on result it'll return .onPurchaseCompleted with product and premium Statust or .onPurchaseFailed with an error

```
purchase(with product: AdaptyPaywallProduct, source: String)
```


# 7. Restore


PremiumManager has a function named restorePurchase that will start initialization of restore Purchase, based on the result it'll send onRestoreCompleted or onRestoreFailed with an error.


# 8. Accessing Premium State


When Adapty's activation is done, it'll automatically update PremiumManager's isPremium variable. This isPremium will be also updated once purchase or restore event is completed.


# 9. Logging Paywall Appearance

Every paywall presentation needs to call this function to log appearance on Adapty

```
Task {
  try await PremiumManager.shared.logPaywallOpen(for: paywall.paywall)
}
```
