//
//  PaygateInteractor.swift
//  CodeChallenge
//
//  Created by Андрей Чернышев on 20.02.2024.
//

import RxSwift
import OtterScaleiOS

final class PaygateInteractor {
    enum Action {
        case buy(String)
        case restore
    }
    
    enum PurchaseActionResult {
        case cancelled
        case completed(Bool)
    }
    
    private lazy var iapManager = IAPManager()
    private lazy var sessionManager = SessionManager()
}

// MARK: Public
extension PaygateInteractor {
    func makeActiveSubscription(by action: Action) -> Single<PurchaseActionResult> {
        switch action {
        case .buy(let productId):
            return purchase(productId: productId)
        case .restore:
            return restore()
        }
    }
}

// MARK: Private
private extension PaygateInteractor {
    func purchase(productId: String) -> Single<PurchaseActionResult> {
        iapManager
            .buyProduct(with: productId)
            .flatMap { iapResult -> Single<PurchaseActionResult> in
                if case .cancelled = iapResult {
                    return .just(.cancelled)
                }
                
                return Single<PurchaseActionResult>.create { single in
                    OtterScale.shared.updatePaymentData(forceValidation: true, completion: { [weak self] paymentData in
                        guard let self else { return }
                        
                        let isTrial: Bool = {
                            guard let subs = paymentData?.subscriptions.appleAppStore.last(where: { $0.productID == productId }) else {
                                return false
                            }
                            return subs.status == .trial
                        }()
                        if !isTrial {
                            FacebookManager.shared.logEvent(name: "fb_mobile_purchase")
                        }
                        
                        let hasActiveSubscriptions = sessionManager.hasActiveSubscriptions()
                        let result = PurchaseActionResult.completed(hasActiveSubscriptions)
                        single(.success(result))
                    }, notifyMediator: false)
                    
                    return Disposables.create()
                }
            }
            .catchAndReturn(.completed(false))
    }
    
    func restore() -> Single<PurchaseActionResult> {
        iapManager
            .restorePurchases()
            .flatMap { iapResult -> Single<PurchaseActionResult> in
                Single<PurchaseActionResult>.create { single in
                    OtterScale.shared.updatePaymentData(forceValidation: true, completion: { [weak self] paymentData in
                        guard let self else { return }
                        
                        let hasActiveSubscriptions = sessionManager.hasActiveSubscriptions()
                        let result = PurchaseActionResult.completed(hasActiveSubscriptions)
                        single(.success(result))
                    }, notifyMediator: false)
                    
                    return Disposables.create()
                }
            }
            .catchAndReturn(.completed(false))
    }
}
