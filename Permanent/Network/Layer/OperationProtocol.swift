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
    
    func execute(in requestDispatcher: RequestDispatcherProtocol, completion: @escaping (Output) -> Void) -> Void
    
    func cancel() -> Void
}

enum OperationResult {
    case json(_: Any?, _: HTTPURLResponse?)
    
    case file(_: Data?, _: HTTPURLResponse?) // URL?
    
    case error(_: Error?, _: HTTPURLResponse?)
}

protocol RequestDispatcherProtocol {
    init(environment: EnvironmentProtocol, networkSession: NetworkSessionProtocol)
    
    func execute(request: RequestProtocol, completion: @escaping (OperationResult) -> Void) -> URLSessionTask?
}
