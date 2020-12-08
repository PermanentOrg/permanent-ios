//  
//  ShareLinkViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 08.12.2020.
//

import Foundation

typealias ShareLinkResponse = (SharebyURLVO?, String?) -> Void

protocol ShareLinkViewModelDelegate: ViewModelDelegateInterface {
    func getShareLink(then handler: @escaping ShareLinkResponse)
}

class ShareLinkViewModel: NSObject, ViewModelInterface {
    var csrf: String = ""
    var fileViewModel: FileViewModel!
    weak var delegate: ShareLinkViewModelDelegate?
}

extension ShareLinkViewModel: ShareLinkViewModelDelegate {
    func getShareLink(then handler: @escaping ShareLinkResponse) {
        let apiOperation = APIOperation(ShareEndpoint.getLink(file: fileViewModel, csrf: csrf))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<SharebyURLVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<SharebyURLVO>.decoder
                    ),
                    model.isSuccessful else {
                    handler(nil, .errorMessage)
                    return
                }
            
                handler(model.results.first?.data?.first, nil)
                
            case .error(let error, _):
                handler(nil, error?.localizedDescription)
                
            default:
                break
            }
        }
    }
    
    
}
