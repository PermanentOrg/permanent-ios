//
//  WebViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.02.2021.
//

import UIKit
import WebKit

class WebViewController: UIViewController {
    var webView = WKWebView()
    var file : FileViewModel!
    var csrf : String!
    var operation : APIOperation?
    override func loadView() {
        self.view = webView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let downloadInfo = FileDownloadInfoVM(
            folderLinkId: file.folderLinkId,
            parentFolderLinkId: file.parentFolderLinkId
        )
        
        getRecord(downloadInfo) { (record, error) in
            let downloadURL = record?.recordVO?.fileVOS?.first?.downloadURL
            if let url = URL(string: downloadURL) {
                let request = URLRequest(url: url)
                self.webView.load(request)
            }
        }
        

    }
    
    fileprivate func getRecord(_ file: FileDownloadInfo, then handler: @escaping GetRecordResponse) {
        let apiOperation = APIOperation(FilesEndpoint.getRecord(itemInfo: (file.folderLinkId, file.parentFolderLinkId, csrf)))
        self.operation = apiOperation
        
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
