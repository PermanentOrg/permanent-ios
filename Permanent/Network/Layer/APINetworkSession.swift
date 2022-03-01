//
//  APINetworkSession.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//

import Foundation

class APINetworkSession: NSObject {
    /// The URLSession handing the URLSessionTaks.
    var session: URLSession!

    override public convenience init() {
        self.init(configuration: nil)
    }

    public init(configuration: URLSessionConfiguration?) {
        super.init()
        if let configuration = configuration {
            self.session = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        } else {
            self.session = URLSession.shared
        }
    }
}

extension APINetworkSession: NetworkSessionProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask? {
        let dataTask = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completionHandler(data, response, error)
            }
        }

        return dataTask
    }

    func uploadTask(with request: URLRequest, progressHandler: ProgressHandler?, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask? {
        completion(nil, nil, NSError(domain: "org.permanent", code: 1000, userInfo: nil))
        return nil
    }

    func downloadTask(with request: URLRequest, fileName: String, progressHandler: ProgressHandler?, completion: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask? {
        completion(nil, nil, NSError(domain: "org.permanent", code: 1000, userInfo: nil))
        return nil
    }
}
