//
//  FacebookManager.swift
//  Soccer
//
//  Created by Андрей Чернышев on 29.03.2022.
//

import FBSDKCoreKit
import OtterScaleiOS
import RxSwift

final class FacebookManager: NSObject {
    static let shared = FacebookManager()
    
    private override init() {
        super.init()
    }
}

// MARK: OtterScaleReceiptValidationDelegate
extension FacebookManager: OtterScaleReceiptValidationDelegate {
    func otterScaleDidValidatedReceipt(with result: AppStoreValidateResult?) {
        guard let otterScaleID = result?.externalUserID ?? result?.internalUserID else {
            return
        }
        
        guard otterScaleID != OtterScale.shared.getAnonymousID() else {
            return
        }
        
        set(userID: otterScaleID)
        
        logEvent(name: "client_user_id_synced")
    }
}

// MARK: Public
extension FacebookManager {
    func initialize(app: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        ApplicationDelegate.shared.application(app, didFinishLaunchingWithOptions: launchOptions)
        
        Settings.shared.isAdvertiserTrackingEnabled = true
        
        AppEvents.shared.activateApp()
        
        OtterScale.shared.addReceiptValidation(delegate: self)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) {
        ApplicationDelegate.shared.application(app, open: url, options: options)
    }
    
    func set(userID: String) {
        AppEvents.shared.userID = userID
    }
    
    func logEvent(name: String) {
        let eventName = AppEvents.Name(name)
        AppEvents.shared.logEvent(eventName)
    }
}
