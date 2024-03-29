//
//  OperationProtocol.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//

import Foundation

protocol OperationProtocol {
    associatedtype Output
    
    var request: RequestProtocol { get }
    
    func execute(in requestDispatcher: RequestDispatcherProtocol, completion: @escaping (Output) -> Void)
    
    func cancel()
}

enum OperationResult {
    case json(_: Any?, _: HTTPURLResponse?)
    
    case file(_: URL?, _: HTTPURLResponse?)
    
    case error(_: Error?, _: HTTPURLResponse?)
}

protocol RequestDispatcherProtocol {
    init(environment: EnvironmentProtocol, networkSession: NetworkSessionProtocol)
    
    func execute(request: RequestProtocol, createdTask: @escaping (URLSessionTask?) -> Void, completion: @escaping (OperationResult) -> Void)
}
