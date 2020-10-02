//
//  SplashViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 25/09/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import Foundation

class SplashViewModel: ViewModelInterface {
    weak var delegate: SplashViewModelDelegate?
}

protocol SplashViewModelDelegate: ViewModelDelegateInterface {
    func verifyLoggedIn(then handler: @escaping (AuthStatus) -> Void)
}

extension SplashViewModel: SplashViewModelDelegate {
    func verifyLoggedIn(then handler: @escaping (AuthStatus) -> Void) {
        let requestDispatcher = APIRequestDispatcher()
        let verifyOperation = APIOperation(AuthenticationEndpoint.verifyAuth)

        verifyOperation.execute(in: requestDispatcher) { result in
            switch result {
            case .json(let response, _):
                let status = self.extractAuthStatus(response)
                handler(status)

            case .error:
                handler(.error)

            default:
                break
            }
        }
    }

    fileprivate func extractAuthStatus(_ jsonObject: Any?) -> AuthStatus {
        guard let json = jsonObject else { return .error }

        let decoder = JSONDecoder()

        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            let authResponse = try decoder.decode(AuthResponse.self, from: data)
            let authValue = authResponse.results?.first?.data?.first?.simpleVO?.value ?? false
            return authValue ? .loggedIn : .loggedOut
        } catch {
            return .error
        }
    }
}

enum AuthStatus {
    case loggedIn
    case loggedOut
    case error
}
