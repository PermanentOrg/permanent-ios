//
//  APIOperation.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//

import Foundation

class APIOperation: OperationProtocol {
    typealias Output = OperationResult
    
    private var task: URLSessionTask?
    
    internal var request: RequestProtocol
    
    init(_ request: RequestProtocol) {
        self.request = request
    }
    
    func execute(in requestDispatcher: RequestDispatcherProtocol, completion: @escaping (OperationResult) -> Void) {
        task = requestDispatcher.execute(request: request, completion: { result in
            completion(result)
        })
    }
    
    func cancel() {
        task?.cancel()
    }
}
