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
    
    fileprivate var csrf: String = ""
    
    var isBusy: Bool = false {
        didSet {
            viewDelegate?.updateSpinner(isLoading: isBusy)
        }
    }
    
    var hasData: Bool { !invites.isEmpty }
    
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
                
                self.csrf = model.csrf
                self.populateData(inviteVOS)
                self.viewDelegate?.updateScreen(status: .success)
                
            case .error(let error, _):
                self.viewDelegate?.updateScreen(status: .error(message: (error as? APIError)?.message))
                
            default:
                fatalError()
            }
        }
    }
    
    func handleInvite(operation: InviteOperation) {
        isBusy = true
        
        let apiOperation = APIOperation(operation.apiOperation(csrf: self.csrf))
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            self.isBusy = false
            
            switch result {
            case .json(let response, _):
                
                guard
                    let model: APIResults<InviteVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<InviteVO>.decoder),
                    
                    model.isSuccessful
                    
                else {
                    self.viewDelegate?.refreshList(status: .error(message: APIError.parseError(nil).message))
                    return
                }
                
                self.viewDelegate?.refreshList(status: .success)
                
            case .error(let error, _):
                self.viewDelegate?.refreshList(status: .error(message: (error as? APIError)?.message))
                
            default:
                fatalError()
            }
        }
    }
    
    func sendInvite(info: [String]?) {
        guard
            let inviteInfo = info,
            let name = inviteInfo.first,
            let email = inviteInfo.last,
            name.isNotEmpty, email.isNotEmpty else { return }
     
        viewDelegate?.dismissDialog()
        handleInvite(operation: .send(name: name, email: email))
    }
    
    fileprivate func populateData(_ invites: [InviteVO]) {
        self.invites.removeAll()
        
        invites.forEach {
            guard let invite = $0.invite else { return  }
        
            let inviteVM = InviteVM(invite: invite)
            
            // Show only items with `pending` status.
            if inviteVM.status == .pending {
                self.invites.append(inviteVM)
            }
            
        }
    }
}

extension InviteViewModel: InviteViewModelDelegate {
    var numberOfItems: Int { invites.count }
    
    func itemFor(row: Int) -> Invite { invites[row] }
}
