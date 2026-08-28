# Paywall Implementation Plan

**Status:** Ready to build. Follow in order.

---

## 1. Create `StoreManager.swift`

New file: `TheSeat/StoreManager.swift`

```swift
import Foundation
import StoreKit

@MainActor @Observable
final class StoreManager {

    var isUnlocked: Bool = false
    var product: Product?
    var isPurchasing: Bool = false

    private let productID = "com.bjanish.askme.unlock"

    init() {
        Task { await loadProduct() }
        Task { await checkEntitlement() }
        Task { await listenForTransactions() }
    }

    // MARK: - Load Product

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [productID])
            product = products.first
        } catch {
            #if DEBUG
            print("[STORE] Failed to load product: \(error)")
            #endif
        }
    }

    // MARK: - Check Entitlement

    func checkEntitlement() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID {
                isUnlocked = true
                return
            }
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product, !isPurchasing else { return }
        isPurchasing = true
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    isUnlocked = true
                    await transaction.finish()
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            #if DEBUG
            print("[STORE] Purchase failed: \(error)")
            #endif
        }
        isPurchasing = false
    }

    // MARK: - Restore

    func restore() async {
        do {
            try await AppStore.sync()
            await checkEntitlement()
        } catch {
            #if DEBUG
            print("[STORE] Restore failed: \(error)")
            #endif
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result,
               transaction.productID == productID {
                isUnlocked = true
                await transaction.finish()
            }
        }
    }
}
```

---

## 2. Create `PaywallView.swift`

New file: `TheSeat/PaywallView.swift`

Design: dark background, gold accents, Cinzel headings. Matches app theme.

```swift
import SwiftUI

struct PaywallView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss

    private let gold = Color(red: 0.85, green: 0.70, blue: 0.40)

    var body: some View {
        ZStack {
            Color(white: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Chair icon
                Image("SeatChair")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .opacity(0.85)

                // Headline
                Text("UNLIMITED HOSTING")
                    .font(.custom("Cinzel-Regular", size: 24))
                    .foregroundStyle(gold)
                    .tracking(3)

                // Subtitle
                Text("You've used your 5 free sessions.\nUnlock unlimited hosting for life.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Purchase button
                Button {
                    Task { await storeManager.purchase() }
                } label: {
                    Group {
                        if storeManager.isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Unlock for \(storeManager.product?.displayPrice ?? "$0.99")")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(gold.opacity(0.3))
                            .stroke(gold, lineWidth: 1)
                    )
                }
                .disabled(storeManager.isPurchasing)
                .padding(.horizontal, 40)

                // Restore
                Button {
                    Task { await storeManager.restore() }
                } label: {
                    Text("Restore Purchase")
                        .font(.subheadline)
                        .foregroundStyle(gold.opacity(0.7))
                }

                Spacer()

                // Dismiss
                Button("Not Now") { dismiss() }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 40)
            }
        }
        .onChange(of: storeManager.isUnlocked) { _, unlocked in
            if unlocked { dismiss() }
        }
    }
}
```

---

## 3. Add Session Counting to `SessionManager.swift`

Add property:

```swift
@ObservationIgnored var hostSessionCount: Int {
    get { UserDefaults.standard.integer(forKey: "hostSessionCount") }
    set { UserDefaults.standard.set(newValue, forKey: "hostSessionCount") }
}
```

Increment in the `.join` handler — ONLY when `connectedPeers` was empty before this join (first player joining = a real session):

```swift
case .join(let name, let incomingDeviceID):
    // ... existing dedup/name logic ...

    // Session count: increment on FIRST player joining this hosting session
    if connectedPeers.isEmpty {
        hostSessionCount += 1
    }

    // ... rest of existing .join code (append to connectedPeers, etc.) ...
```

**Important:** The increment happens BEFORE `connectedPeers.append(finalName)` so the `.isEmpty` check works. Or use a `sessionCounted` bool that resets in `startHosting()`.

Alternative (cleaner — avoids ordering issues):

```swift
@ObservationIgnored private var sessionCounted: Bool = false
```

In `startHosting()`:
```swift
sessionCounted = false
```

In `.join` handler, after appending to `connectedPeers`:
```swift
if !sessionCounted {
    sessionCounted = true
    hostSessionCount += 1
}
```

In `tearDown()`:
```swift
sessionCounted = false
```

---

## 4. Gate Logic in `ContentView.swift`

On "Take the Seat" button tap:

```swift
Button {
    #if DEBUG
    if !paywallEnabled {
        sessionManager.startHosting()
        return
    }
    #endif

    if storeManager.isUnlocked || sessionManager.hostSessionCount < 5 {
        sessionManager.startHosting()
    } else {
        showPaywall = true
    }
} label: {
    // existing button label
}
.sheet(isPresented: $showPaywall) {
    PaywallView()
        .environment(storeManager)
}
```

Add state:
```swift
@State private var showPaywall = false
```

---

## 5. Wire Restore in `SettingsView.swift`

The "Restore Purchase" row already exists. Wire it:

```swift
settingsRow("Restore Purchase") {
    Task { await storeManager.restore() }
}
```

Pass `StoreManager` via environment from `TheSeatApp.swift`.

---

## 6. Wire StoreManager in `TheSeatApp.swift`

```swift
@State private var storeManager = StoreManager()
```

In body:
```swift
ContentView()
    .environment(sessionManager)
    .environment(storeManager)
```

---

## 7. Debug Flag

In `ContentView.swift` (or a shared debug file):

```swift
#if DEBUG
private let paywallEnabled = false  // Set to true to test paywall flow
#endif
```

Optional: add a debug-only button in Settings to reset `hostSessionCount` to 0 for testing:

```swift
#if DEBUG
settingsRow("Reset Session Count (DEBUG)") {
    UserDefaults.standard.set(0, forKey: "hostSessionCount")
}
#endif
```

---

## 8. App Store Connect Setup

- Create non-consumable in-app purchase in App Store Connect
- Product ID: `com.bjanish.askme.unlock`
- Reference name: "Unlimited Hosting"
- Price: $0.99
- Description: "Unlock unlimited hosting sessions in The Seat."
- Screenshot: capture of PaywallView for review

---

## 9. Testing Checklist

- [ ] Fresh install: host 5 times (with a player joining each), 6th shows paywall
- [ ] Purchase completes → paywall dismisses → hosting works immediately
- [ ] Kill app, relaunch → still unlocked (entitlement check on init)
- [ ] Restore Purchase works (after clearing sandbox purchase)
- [ ] `paywallEnabled = false` → paywall never shows (debug)
- [ ] `paywallEnabled = true` + reset count → full flow testable
- [ ] Sessions where no player joins do NOT increment count
- [ ] Joining someone else's session is always free (no paywall)

---

## Build Order

1. `StoreManager.swift` (new file)
2. `PaywallView.swift` (new file)
3. `TheSeatApp.swift` (add storeManager environment)
4. `SessionManager.swift` (add hostSessionCount + sessionCounted)
5. `ContentView.swift` (gate logic + sheet + debug flag)
6. `SettingsView.swift` (wire restore)
7. Test with `paywallEnabled = true` and sandbox account
8. Create IAP in App Store Connect
