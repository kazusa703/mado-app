import StoreKit

@Observable
final class StoreKitService {
    static let shared = StoreKitService()

    private let proProductId = "com.imaiissatsu.mado.pro"

    private(set) var proProduct: Product?
    private(set) var isPurchased = false
    private(set) var isLoading = false

    private var updateListenerTask: Task<Void, Never>?

    private init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
        Task { await checkPurchaseStatus() }
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [proProductId])
            proProduct = products.first
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase() async throws -> Bool {
        guard let product = proProduct else { return false }
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            isPurchased = true
            UserSettings.shared.isPro = true
            return true
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }

        try? await AppStore.sync()
        await checkPurchaseStatus()
    }

    private func checkPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == proProductId {
                isPurchased = true
                UserSettings.shared.isPro = true
                return
            }
        }
        isPurchased = false
        UserSettings.shared.isPro = false
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.checkPurchaseStatus()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
