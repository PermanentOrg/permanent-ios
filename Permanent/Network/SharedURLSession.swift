//
//  SharedURLSession.swift
//  Permanent
//
//  Created by Constantin Georgiu on 17/12/2020.
//

import Foundation

class SharedURLSession {
    static var shared = SharedURLSession()

    var session: URLSession!
    
    private init() {
        // Configure the default URLSessionConfiguration.
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForResource = 300
        sessionConfiguration.waitsForConnectivity = false

        // Create a `OperationQueue` instance for scheduling the delegate calls and completion handlers.
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 3
        queue.qualityOfService = .userInitiated

        session = URLSession(configuration: sessionConfiguration, delegate: nil, delegateQueue: queue)
    }
}
