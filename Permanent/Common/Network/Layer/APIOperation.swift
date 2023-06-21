//
//  APIOperation.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//

import Foundation

class APIOperation: OperationProtocol {
    typealias Output = OperationResult
    
    private var cancelled: Bool = false
    private var task: URLSessionTask?
    
    internal var request: RequestProtocol
    
    init(_ request: RequestProtocol) {
        self.request = request
    }
    
    func execute(in requestDispatcher: RequestDispatcherProtocol, completion: @escaping (OperationResult) -> Void) {
        requestDispatcher.execute(
            request: request,
            createdTask: { task in
                self.task = task
                
                if self.cancelled {
                    task?.cancel()
                }
            },
            completion: { result in
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        )
    }
    
    func cancel() {
        cancelled = true
        
        task?.cancel()
    }
}
