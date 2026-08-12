//
//  BaseOperation.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 09.06.2021.
//

import Foundation

class BaseOperation: Operation {
    // Guarded by `stateLock`: `finish()` runs on a URLSession callback thread while the queue reads
    // these via KVO on another, and an unsynchronized write can drop the finished transition.
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
        // Marks the task finished. KVO notifications fire outside the lock, to avoid re-entrancy if an
        // observer reads these synchronously.
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
