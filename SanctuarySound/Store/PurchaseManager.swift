// ============================================================================
// PurchaseManager.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM Service Layer
// Purpose: StoreKit 2 integration for the SanctuarySound Pro in-app purchase.
//          Manages product loading, purchase flow, transaction verification,
//          entitlement checking, and purchase restoration. Uses UserDefaults
//          as a cache with StoreKit as the source of truth.
// ============================================================================

import StoreKit
import SwiftUI


// MARK: - ─── Purchase Manager ─────────────────────────────────────────────

@MainActor
final class PurchaseManager: ObservableObject {

    // ── Published State ──
    @Published private(set) var isPro: Bool = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseState: PurchaseState = .idle
    @Published var showPaywall: Bool = false

    // ── Constants ──
    static let proProductID = "com.sanctuarysound.app.pro"
    private let entitlementCacheKey = "sanctuarysound_pro_unlocked"

    // ── Transaction Listener ──
    private var transactionListener: Task<Void, Never>?


    // MARK: - ─── Lifecycle ────────────────────────────────────────────────

    init() {
        isPro = UserDefaults.standard.bool(forKey: entitlementCacheKey)
        transactionListener = listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
    }

    /// Load available products from the App Store.
    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(
                for: [Self.proProductID]
            )
            products = storeProducts
        } catch {
            products = []
        }
    }

    /// Verify entitlement status against StoreKit's source of truth.
    func checkEntitlement() async {
        var foundEntitlement = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.proProductID {
                foundEntitlement = true
                break
            }
        }

        isPro = foundEntitlement
        UserDefaults.standard.set(foundEntitlement, forKey: entitlementCacheKey)
    }


    // MARK: - ─── Purchase Flow ────────────────────────────────────────────

    /// Initiate a purchase of SanctuarySound Pro.
    func purchase() async {
        guard let product = products.first(where: { $0.id == Self.proProductID }) else {
            purchaseState = .failed("Product not available. Please try again later.")
            return
        }

        purchaseState = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerification(verification)
                await transaction.finish()
                isPro = true
                UserDefaults.standard.set(true, forKey: entitlementCacheKey)
                purchaseState = .purchased

            case .userCancelled:
                purchaseState = .idle

            case .pending:
                purchaseState = .pending

            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed("Purchase failed. Please try again.")
        }
    }

    /// Restore previous purchases.
    func restore() async {
        purchaseState = .restoring
        do {
            try await AppStore.sync()
            await checkEntitlement()
            purchaseState = isPro ? .purchased : .idle
        } catch {
            purchaseState = .failed("Restore failed. Please try again.")
        }
    }


    // MARK: - ─── Free-Tier Limits ─────────────────────────────────────────

    /// Maximum channels allowed in free tier.
    static let freeChannelLimit = 3

    /// Maximum saved vocalist profiles in free tier.
    static let freeVocalistLimit = 3

    /// Maximum saved inputs in free tier.
    static let freeInputLimit = 5

    /// Maximum saved services in free tier.
    static let freeServiceLimit = 1

    /// Maximum SPL monitoring duration in free tier (seconds).
    static let freeSPLDuration: TimeInterval = 300  // 5 minutes

    /// Check if a feature is available, showing paywall if not.
    func requirePro() -> Bool {
        if isPro { return true }
        showPaywall = true
        return false
    }


    // MARK: - ─── Private Helpers ──────────────────────────────────────────

    /// Listen for transaction updates (renewals, revocations, external purchases).
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                if transaction.productID == PurchaseManager.proProductID {
                    await transaction.finish()
                    await MainActor.run {
                        self?.isPro = true
                        UserDefaults.standard.set(true, forKey: self?.entitlementCacheKey ?? "")
                    }
                }
            }
        }
    }

    /// Verify a transaction result from StoreKit.
    private func checkVerification<T>(
        _ result: VerificationResult<T>
    ) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            throw error
        }
    }
}


// MARK: - ─── Purchase State ───────────────────────────────────────────────

enum PurchaseState: Equatable {
    case idle
    case purchasing
    case purchased
    case pending
    case restoring
    case failed(String)

    var isLoading: Bool {
        switch self {
        case .purchasing, .restoring: return true
        default: return false
        }
    }
}
