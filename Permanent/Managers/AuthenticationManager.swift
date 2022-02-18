//
//  AuthenticationManager.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 09.02.2022.
//

import UIKit
import KeychainSwift
import AppAuth

class AuthenticationManager {
    static let keychainAuthDataKey = "org.permanent.authData"
    
    static let shared = AuthenticationManager()
    
    var authState: OIDAuthState?
    var currentAuthorizationFlow: OIDExternalUserAgentSession?
    
    init() {
        NotificationCenter.default.addObserver(forName: APIRequestDispatcher.sessionExpiredNotificationName, object: nil, queue: nil) { [weak self] notification in
            self?.authState = nil
            KeychainSwift().delete(Self.keychainAuthDataKey)
        }
    }
    
    func reloadSession() -> Bool {
        if let authData = KeychainSwift().getData(Self.keychainAuthDataKey),
            let authState = try? NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: authData) {
            self.authState = authState
            
            return true
        }
        
        return false
    }
    
    func performLoginFlow(fromPresentingVC presentingVC: UIViewController, completion: @escaping ServerResponse) {
        guard let authorizationEndpoint = URL(string: APIEnvironment.defaultEnv.authorizationURL),
            let tokenEndpoint = URL(string: APIEnvironment.defaultEnv.tokenURL),
            let bundleId = Bundle.main.bundleIdentifier,
            let redirectURL = URL(string: bundleId + "://auth-redirect") else {
            completion(.error(message: .errorMessage))
            return
        }
        
        let configuration = OIDServiceConfiguration(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint)
        let request = OIDAuthorizationRequest(
            configuration: configuration,
            clientId: authServiceInfo.clientId,
            clientSecret: authServiceInfo.clientSecret,
            scopes: ["offline_access"],
            redirectURL: redirectURL,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil
        )
        
        currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: presentingVC) { authState, error in
            if let authState = authState {
                self.authState = authState
                print("\n\nAuthorization token: \(authState.lastTokenResponse?.accessToken)\n\n")
                
                completion(.success)
            } else {
                self.authState = nil
                
                completion(.error(message: "Authorization error".localized()))
            }
        }
    }
    
    func saveSession() {
        guard let authState = authState else {
            return
        }
        
        do {
            let authData = try NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: true)
            KeychainSwift().set(authData, forKey: Self.keychainAuthDataKey)
        } catch {
            print("Failed to save auth data")
        }
    }
    
    func logout() {
        authState = nil
        KeychainSwift().delete(Self.keychainAuthDataKey)
    }
}
