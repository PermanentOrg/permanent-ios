//
//  InviteViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 26.01.2021.
//

import Foundation

class InviteViewModel {
    // MARK: - Delegates
    
    var viewDelegate: InviteViewModelViewDelegate?
    
    // MARK: - Properties
    
    fileprivate var invites: [Invite] = []
    
    var isBusy: Bool = false {
        didSet {
            viewDelegate?.updateSpinner(isLoading: isBusy)
        }
    }
    
    // MARK: - Events
    
    func start() {
        fetchMyInvites()
    }
    
    // MARK: - Network
    
    func fetchMyInvites() {
        isBusy = true
        
        let apiOperation = APIOperation(InviteEndpoint.getMyInvites)
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            self.isBusy = false
            
            switch result {
            case .json(let response, _):
                
                guard
                    let model: APIResults<InviteVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<InviteVO>.decoder),
                    
                    model.isSuccessful,
                    let inviteVOS = model.results.first?.data
                    
                else {
                    self.viewDelegate?.updateScreen(status: .error(message: APIError.parseError(nil).message))
                    return
                }
                
                self.populateData(inviteVOS)
                self.viewDelegate?.updateScreen(status: .success)
                
            case .error(let error, _):
                self.viewDelegate?.updateScreen(status: .error(message: (error as? APIError)?.message))
                
            default:
                fatalError()
            }
        }
    }
    
    fileprivate func populateData(_ invites: [InviteVO]) {
        invites.forEach {
            guard let invite = $0.invite else { return  }
        
            let inviteVM = InviteVM(invite: invite)
            self.invites.append(inviteVM)
        }
    }
}

extension InviteViewModel: InviteViewModelDelegate {
    var numberOfItems: Int { invites.count }
    
    func itemFor(row: Int) -> Invite { invites[row] }
}
