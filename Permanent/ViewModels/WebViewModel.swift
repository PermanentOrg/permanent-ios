//
//  WebViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.02.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import UIKit
import WebKit

class WebViewModel: ViewModelInterface {
    var csrf : String!
    

//protocol WebViewModelDelegate: ViewModelDelegateInterface {
//    func downloadFile(csrf: String,file: FileViewModel, then handler: @escaping (Bool,URLRequest) -> Void)
//}
    func downloadFile(csrf: String, file: FileViewModel, then handler: @escaping (Bool,URLRequest?) -> Void) {
        
         let downloadInfo = FileDownloadInfoVM(
            folderLinkId: file.folderLinkId,
            parentFolderLinkId: file.parentFolderLinkId
        )
         getRecord(downloadInfo,csrf) { (record, error) in

            let downloadURL = record?.recordVO?.fileVOS?.first?.downloadURL
            if let url = URL(string: downloadURL) {
                //self.request = URLRequest(url: url)
                handler(true,URLRequest(url: url))
            } else {
                handler(false,nil)
            }
            return
        }
    }
    
    func getRecord(_ file: FileDownloadInfo,_ csrf: String, then handler: @escaping GetRecordResponse) {
        var operation : APIOperation?
        let apiOperation = APIOperation(FilesEndpoint.getRecord(itemInfo: (file.folderLinkId, file.parentFolderLinkId, csrf)))
        operation = apiOperation
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<RecordVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<RecordVO>.decoder
                    ),
                    model.isSuccessful
                    
                else {
                    handler(nil, APIError.parseError(nil))
                    return
                }
                 
                handler(model.results.first?.data?.first, nil)
                    
            case .error(let error, _):
                handler(nil, error)
                    
            default:
                break
            }
        }
    }
}

