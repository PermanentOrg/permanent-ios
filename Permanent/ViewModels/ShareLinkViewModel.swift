//  
//  ShareLinkViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 08.12.2020.
//

import Foundation

typealias ShareLinkResponse = (SharebyURLVOData?, String?) -> Void

protocol ShareLinkViewModelDelegate: ViewModelDelegateInterface {
    func getShareLink(then handler: @escaping ShareLinkResponse)
}

class ShareLinkViewModel: NSObject, ViewModelInterface {
    var csrf: String = ""
    var fileViewModel: FileViewModel!
    var shareVO: SharebyURLVOData?
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
            
                self.shareVO = model.results.first?.data?.first?.shareByURLVO
                handler(self.shareVO, nil)
                
            case .error(let error, _):
                handler(nil, error?.localizedDescription)
                
            default:
                break
            }
        }
    }
    
    func revokeLink(then handler: @escaping ServerResponse) {
        guard let shareVO = shareVO else {
            handler(.error(message: .errorMessage))
            return
        }
        
        let apiOperation = APIOperation(ShareEndpoint.revokeLink(link: shareVO, csrf: csrf))
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<NoDataModel> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<NoDataModel>.decoder
                    ),
                    model.isSuccessful else {
                    handler(.error(message: .errorMessage))
                    return
                }
                
                handler(.success)
            
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
}
