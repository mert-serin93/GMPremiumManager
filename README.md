# 1. Configure


PremiumManager needs to be configured on AppDelegate or SwiftUI's App init, only once. For customerUserId you need to use the unique identifier that you created once user installed the app. If you are using something from Firebase ID or AppsFlyer ID you can also pass this one here.


`PremiumManager.configure(key: <YOUR_ADAPTY_KEY>, observerMode: false, idfaCollectionDisabled: false, customerUserId: <Custom_user_id that you use to identify user> ipAddressCollectionDisabled: false, implementation: GMPremiumManagerImpl())`


# 2. Activation and Fetching Paywall Flows


Once PremiumManager is configured you need to activate and fetch all paywall flows for the active placements. Adapty iOS SDK v4 uses flows as the SDK model for both Flow Builder and existing Paywall Builder content; this package keeps the existing `fetchAllPaywalls` and `getPaywall` method names for compatibility. Adapty doesn't have any build in function to fetch active placements so we need to create an enum that has all the placements that's been created on Adapty. (you can find AdaptyPlacements enum on example picture)
After you created this enum you can activate Adapty and fetch all the paywall flows for placements.

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



This will fetch all the paywall flows and keep them in the dictionary for later uses.

If a Flow Builder screen uses custom tags, custom timers, custom assets, observer-mode purchase handling, or system requests, pass the needed resolvers while fetching the flow configurations:

```swift
let options = PremiumManagerFlowConfigurationOptions(
    tagResolver: tagResolver,
    timerResolver: timerResolver,
    assetsResolver: assetsResolver,
    systemRequestsHandler: systemRequestsHandler
)

Task {
    try await PremiumManager.shared.fetchAllPaywalls(
        for: AdaptyPlacements.allCases,
        flowConfigurationOptions: options
    )
}
```

Only pass the resolvers your flow actually uses. Calls without `flowConfigurationOptions` keep the default behavior.


# 3. Listening Premium Manager events


PremiumManager has eventPassthrough  variable that publishes all the changes that happens in Adapty SDK, you can find the full event list on PremiumManager's Event enum. It's a combine publisher so for listening changes to show error or show success pop-up you need to listen wherever it's needed. For potential memory leaks you need to make sure that it's removed if you are listening from ViewController.
You can listen changes like this:

```
PremiumManager.shared.eventPassthrough.sink {[weak self] output in
      guard let self else { return }
      // Do what you want to do with output in switch case
    }.store(in: &storage)
```

storage needs to be created where you want to listen these changes. 

You can initialize storage by 

```
import Combine

var storage = Set<AnyCancellables>()
```


the ones start with APB prefix are AdaptyUI flow events. The prefix is kept for compatibility with existing listeners.

Forwarded Flow events include appear/disappear, actions, product selection, purchase and restore lifecycle, render/product-loading errors, web payment completion, and custom analytic events fired from Flow scripts.


# 4. Accessing Paywall Flow


Once you fetched all the paywall flows, you can access any of them with:

```
PremiumManager.shared.getPaywall(with: placement that you created on AdaptyPlacements)
```



In return you'll get a PremiumManagerModel that contains all the information about products, whether AdaptyUI rendering is enabled, and Remote Config for this particular flow. You can use these products and show them in a custom paywall or use Adapty's Flow Builder/Paywall Builder UI.


# 5. Showing AdaptyUI Paywall Flow


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


GMAdaptyPaywallPresenter has two functions getPaywallViewController and getPaywallSwiftUI to support both UIKit and SwiftUI. All events done on AdaptyUI flow views will send events with the APB prefix (you can find the full list on Events Enum).


# 6. Purchase


PremiumManager has a function name purchase to start purchase process. Based on result it'll return .onPurchaseCompleted with product and premium Statust or .onPurchaseFailed with an error

```
PremiumManager.shared.purchase(with product: AdaptyPaywallProduct, source: String)
```


# 7. Restore


PremiumManager has a function named restorePurchase that will start initialization of restore Purchase, based on the result it'll send onRestoreCompleted or onRestoreFailed with an error.


# 8. Accessing Premium State


When Adapty's activation is done, it'll automatically update PremiumManager's isPremium variable. This isPremium will be also updated once purchase or restore event is completed.


# 9. Checking Access Levels


PremiumManager supports checking multiple access levels beyond just "premium". This is useful when you have different subscription tiers (e.g., "pro", "vip", "basic").

## Published Properties

- `isPremium: Bool` - Tracks if user has either "premium" or "premium-plus" access level
- `activeAccessLevels: [String]` - Array of all currently active access level identifiers

## Check if a Specific Access Level is Active

```swift
// With an existing profile
let hasPro = PremiumManager.shared.hasAccessLevel("pro", in: profile)

// Or fetch the latest profile and check
Task {
    let hasVIP = try await PremiumManager.shared.hasAccessLevel("vip")
}
```

## Get All Active Access Levels

```swift
// From published property (observable)
let levels = PremiumManager.shared.activeAccessLevels

// From an existing profile
let levels = PremiumManager.shared.getActiveAccessLevels(in: profile)

// Or fetch and get
Task {
    let levels = try await PremiumManager.shared.getActiveAccessLevels()
}
```

## Get Detailed Access Level Information

Returns full `AdaptyProfile.AccessLevel` object with expiration date, renewal status, etc.

```swift
// From an existing profile
if let proLevel = PremiumManager.shared.getAccessLevel("pro", in: profile) {
    print("Expires: \(proLevel.expiresAt)")
    print("Will renew: \(proLevel.willRenew)")
}

// Or fetch and get
Task {
    if let vipLevel = try await PremiumManager.shared.getAccessLevel("vip") {
        print("Active: \(vipLevel.isActive)")
    }
}
```

## Observing Access Level Changes (SwiftUI)

```swift
struct ContentView: View {
    @ObservedObject var premiumManager = PremiumManager.shared

    var body: some View {
        if premiumManager.activeAccessLevels.contains("pro") {
            ProFeatureView()
        }
    }
}
```


# 10. Logging Paywall Appearance

For custom paywalls, call this function to log appearance on Adapty. AdaptyUI-rendered Flow Builder and Paywall Builder views are tracked automatically by the SDK.

```
Task {
  try await PremiumManager.shared.logPaywallOpen(for: paywall.flow)
}
```
