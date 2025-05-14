//
//  ChecklistBottomMenuViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.05.2025.

import SwiftUI
import Foundation

struct ChecklistResponse: Model {
    let checklistItems: [ChecklistItem]
}

class ChecklistBottomMenuViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var items: [ChecklistItem] = []
    @Published var viewState: ChecklistViewState = .loading
    
    var completionPercentage: Int {
        let completedCount = items.filter { $0.completed }.count
        return items.isEmpty ? 0 : Int((Double(completedCount) / Double(items.count)) * 100)
    }
    
    init() {
        getMemberChecklist()
    }
    
    func getMemberChecklist() {
        viewState = .loading
        let getMemberChecklistOperation = APIOperation(EventsEndpoint.checklist)
        getMemberChecklistOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .json(let response, _):
                guard
                    let model: ChecklistResponse = JSONHelper.convertToModel(from: response)
                else {
                    self.viewState = .error
                    return
                }
                DispatchQueue.main.async {
                    self.items = model.checklistItems
                    self.viewState = .content
                }
                
            default:
                self.viewState = .error
            }
        }
    }
    
    func setHideChecklist(_ isSuccesfull: @escaping ((Bool) -> Void)) {
        viewState = .loading
        guard let account = AuthenticationManager.shared.session?.account else {
            isSuccesfull(false)
            return
        }
        
        let setChecklistOperation = APIOperation(AccountEndpoint.updateHideChecklist(accountId: account, hideChecklist: true))
        setChecklistOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: APIResults<AccountVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder), model.isSuccessful else {
                    isSuccesfull(false)
                    return
                }
                if let _ = model.results[0].data?[0].accountVO {
                    isSuccesfull(true)
                } else {
                    isSuccesfull(false)
                }
                
            default:
                isSuccesfull(false)
            }
        }
    }
}
