//
//  BaseOperation.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 09.06.2021.
//

import Foundation

class BaseOperation: Operation {
    // keep track of executing and finished states
    fileprivate var _executing = false
    fileprivate var _finished = false
    
    override func start() {
        willChangeValue(forKey: "isExecuting")
        _executing = true
        didChangeValue(forKey: "isExecuting")
    }
    
    func finish() {
        // Change isExecuting to `false` and isFinished to `true`.
        // Taks will be considered finished.
        willChangeValue(forKey: "isExecuting")
        willChangeValue(forKey: "isFinished")
        _executing = false
        _finished = true
        didChangeValue(forKey: "isExecuting")
        didChangeValue(forKey: "isFinished")
    }
    
    override var isExecuting: Bool {
        return _executing
    }
    
    override var isFinished: Bool {
        return _finished
    }
    
    override func cancel() {
        super.cancel()
        
        if isExecuting {
            finish()
        }
    }
}
