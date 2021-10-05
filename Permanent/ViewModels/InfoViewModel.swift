//
//  InfoViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.01.2021.
//

import Foundation
import UIKit

typealias UpdateUserData = (fullName: String?, primaryEmail: String?, primaryPhone: String?, address: String?, city: String?, state: String?, zip: String?, country: String?)

class InfoViewModel: ViewModelInterface {
    weak var delegate: InfoViewModelDelegate?
    var userData: UpdateUserData
    var accountId: String?
    var dataIsNotModified: Bool
    init() {
        self.userData = (nil, nil, nil, nil, nil, nil, nil, nil)
        self.dataIsNotModified = false
    }
    
    var sessionProtocol: NetworkSessionProtocol = APINetworkSession()
}

protocol InfoViewModelDelegate: ViewModelDelegateInterface {
    func getNewCsrf(then handler: @escaping (Bool) -> Void)
    func getUserData(with accountId: String, then handler: @escaping (GetUserDataStatus) -> Void)
    func updateUserData(with accountId: String, userData: UpdateUserData, then handler: @escaping (UpdateUserDataStatus) -> Void)
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
                    return
                }
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

    func getUserData(with accountId: String, then handler: @escaping (GetUserDataStatus) -> Void) {
        let getUserDataOperation = APIOperation(AccountEndpoint.getUserData(accountId: accountId))
        
        let apiDispatch = APIRequestDispatcher(networkSession: sessionProtocol)
        apiDispatch.ignoresMFAWarning = true

        getUserDataOperation.execute(in: apiDispatch) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<AccountVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<NoDataModel>.decoder
                    ),
                    model.isSuccessful
                else {
                    handler(.error(message: .errorMessage))
                    return
                }

                self.userData.primaryEmail = model.results.first?.data?.first?.accountVO?.primaryEmail
                self.userData.fullName = model.results.first?.data?.first?.accountVO?.fullName
                self.userData.address = model.results.first?.data?.first?.accountVO?.address
                self.userData.city = model.results.first?.data?.first?.accountVO?.city
                self.userData.state = model.results.first?.data?.first?.accountVO?.state
                self.userData.zip = model.results.first?.data?.first?.accountVO?.zip
                self.userData.country = model.results.first?.data?.first?.accountVO?.country
                self.userData.primaryPhone = model.results.first?.data?.first?.accountVO?.primaryPhone
                handler(.success(message: .getUserDetailsWasSuccessfully))
                return
            case .error:
                handler(.error(message: .errorMessage))
                return
            default:
                break
            }
        }
    }

    func updateUserData(with accountId: String, userData: UpdateUserData, then handler: @escaping (UpdateUserDataStatus) -> Void) {
        
        let apiDispatch = APIRequestDispatcher(networkSession: sessionProtocol)
        apiDispatch.ignoresMFAWarning = true
        
        guard
            let fullName = userData.fullName,
            fullName.isNotEmpty
        else {
            handler(.error(message: AccountUpdateError.nameFieldIsEmpty.description))
            return
        }
        
        guard
            let primaryEmail = userData.primaryEmail,
            primaryEmail.isValidEmail
        else {
            handler(.error(message: AccountUpdateError.emailIsNotValid.description))
            return
        }
        
        guard dataIsNotModified == false else {
            handler(.error(message: AccountUpdateError.dataIsNotModified.description))
            return
        }

        let updateUserDataOperation = APIOperation(AccountEndpoint.updateUserData(accountId: accountId, updateData: userData))

        updateUserDataOperation.execute(in: apiDispatch) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<NoDataModel> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<NoDataModel>.decoder
                    )
                else {
                    handler(.error(message: .errorMessage))
                    return
                }
                guard
                    model.isSuccessful
                else {
                    let message = model.results.first?.message.first
                    let userDetailsFaieldMessage = AccountUpdateError(rawValue: message ?? .errorUnknown)
                    handler(.error(message: userDetailsFaieldMessage?.description))
                    return
                }
                handler(.success(message: .userDetailsChangedSuccessfully))

            case .error:
                handler(.error(message: .errorMessage))

            default:
                handler(.error(message: .errorMessage))
            }
        }
    }

    func getValuesFromTextFieldValue(receivedData: UpdateUserData) {
        dataIsNotModified = receivedData.fullName == userData.fullName &&
            receivedData.primaryEmail == userData.primaryEmail &&
            receivedData.address == userData.address &&
            receivedData.city == userData.city &&
            receivedData.country == userData.country &&
            receivedData.primaryPhone == userData.primaryPhone &&
            receivedData.state == userData.state &&
            receivedData.zip == userData.zip

        if dataIsNotModified == false {
            userData = receivedData
        }
    }

    func format(with mask: String, phone: String) -> String {
        let numbers = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        var result = ""
        var index = numbers.startIndex // numbers iterator

        for ch in mask where index < numbers.endIndex {
            if ch == "Z" {
                result.append(numbers[index])

                index = numbers.index(after: index)

            } else {
                result.append(ch)
            }
        }
        return result
    }
}

enum GetUserDataStatus: Equatable {
    case success(message: String?)
    case error(message: String?)
}

enum UpdateUserDataStatus: Equatable {
    case success(message: String?)
    case error(message: String?)
}
