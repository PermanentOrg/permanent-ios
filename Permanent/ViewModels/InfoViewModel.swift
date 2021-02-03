//
//  InfoViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.01.2021.
//

import Foundation
import UIKit

class InfoViewModel: ViewModelInterface {
    weak var delegate: InfoViewModelDelegate?
    var apiData: [String: String] = [:]
    var actualCsrf: String?
    var accountID: String?
    var fullName: String?
}

protocol InfoViewModelDelegate: ViewModelDelegateInterface {
    func getNewCsrf(then handler: @escaping (Bool) -> Void)
    func getUserData(with accountId: String, csrf: String, then handler: @escaping (Bool) -> Void)
}

extension InfoViewModel: InfoViewModelDelegate {

    func getNewCsrf(then handler: @escaping (Bool) -> Void) {
        let getNewCsrfOperation = APIOperation(AccountEndpoint.getValidCsrf)

        getNewCsrfOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<NoDataModel> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<NoDataModel>.decoder
                    ),
                    model.isSuccessful

                else {
                    self.apiData["csrf"] = .errorMessage
                    return
                }
                self.apiData["csrf"] = model.csrf
                handler(true)
                return
            case .error:
                handler(false)
                return
            default:
                break
            }
        }
    }
    func getUserData(with accountId: String, csrf: String, then handler: @escaping (Bool) -> Void) {
        let getUserDataOperation = APIOperation(AccountEndpoint.getUserData(accountId: accountId, csrf: csrf))
        
        getUserDataOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<AccountVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<NoDataModel>.decoder
                    ),
                    model.isSuccessful
                else {
                    self.apiData["csrf"] = .errorMessage
                    return
                }
                self.apiData["primaryEmail"] = model.results.first?.data?.first?.accountVO?.primaryEmail
                self.apiData["fullName"] = model.results.first?.data?.first?.accountVO?.fullName
                self.apiData["address"] = model.results.first?.data?.first?.accountVO?.address
                self.apiData["city"] = model.results.first?.data?.first?.accountVO?.city
                self.apiData["state"] = model.results.first?.data?.first?.accountVO?.state
                self.apiData["zip"] = model.results.first?.data?.first?.accountVO?.zip
                self.apiData["country"] = model.results.first?.data?.first?.accountVO?.country
                self.apiData["primaryPhone"] = model.results.first?.data?.first?.accountVO?.primaryPhone
                handler(true)
                return
            case .error:
                handler(false)
                return
            default:
                break
            }
            
          //  print(result)
            
        }
    }
}
