//
//  BaseOperation.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 09.06.2021.
//

import Foundation

class BaseOperation: Operation {
    // keep track of executing and finished states.
    // Guarded by `stateLock`: `finish()` can run on a background URLSession callback thread
    // while the OperationQueue reads `isExecuting`/`isFinished` via KVO on another thread —
    // an unsynchronized read/write is a data race and can drop the finished transition.
    private let stateLock = NSLock()
    private var _executing = false
    private var _finished = false

    override func start() {
        willChangeValue(forKey: "isExecuting")
        stateLock.lock()
        _executing = true
        stateLock.unlock()
        didChangeValue(forKey: "isExecuting")
    }

    func finish() {
        // Change isExecuting to `false` and isFinished to `true`.
        // Task will be considered finished. KVO notifications fire OUTSIDE the lock to avoid
        // re-entrancy if an observer reads isExecuting/isFinished synchronously.
        willChangeValue(forKey: "isExecuting")
        willChangeValue(forKey: "isFinished")
        stateLock.lock()
        _executing = false
        _finished = true
        stateLock.unlock()
        didChangeValue(forKey: "isExecuting")
        didChangeValue(forKey: "isFinished")
    }

    override var isExecuting: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _executing
    }

    override var isFinished: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _finished
    }
    
    override func cancel() {
        super.cancel()
    }
}
