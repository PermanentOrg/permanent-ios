//
//  ActivityFeedViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 21.01.2021.
//

import Foundation

class ActivityFeedViewModel: ActivityFeedViewModelDelegate {
    // MARK: - Delegates
    
    weak var viewDelegate: ActivityFeedViewModelViewDelegate?
    
    fileprivate var notifications: [Notification] = []
    
    // MARK: - Properties
    
    var isBusy: Bool = false {
        didSet {
            viewDelegate?.updateSpinner(isLoading: isBusy)
        }
    }
    
    var numberOfItems: Int {
        return notifications.count
    }
    
    func itemFor(row: Int) -> Notification {
        return notifications[row]
    }
    
    func start() {
        fetchNotifications()
    }
    
    // MARK: - Network
    
    func fetchNotifications() {
        
        isBusy = true
        
        let apiOperation = APIOperation(NotificationsEndpoint.getMyNotifications)
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            self.isBusy = false
            
            switch result {
            case .json(let response, _):
                
                guard
                    let model: APIResults<NotificationVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<NotificationVO>.decoder
                    ),

                    model.isSuccessful,
                    let notifications = model.results.first?.data else {
                    self.viewDelegate?.updateScreen(status: .error(message: APIError.parseError(nil).message))
                    return
                }
                        
                self.notifications = notifications.map { NotificationVM(notification: $0) }
                self.viewDelegate?.updateScreen(status: .success)
                
            case .error(let error, _):
                self.viewDelegate?.updateScreen(status: .error(message: (error as? APIError)?.message))
                
            default:
                fatalError()
            }
        }
    }
}
