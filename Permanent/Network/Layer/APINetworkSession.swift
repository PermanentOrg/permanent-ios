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

    /// A typealias describing a progress and completion handle tuple.
    private typealias ProgressAndCompletionHandlers = (progress: ProgressHandler?, completion: ((URL?, URLResponse?, Error?) -> Void)?)

    /// Dictionary containing associations of `ProgressAndCompletionHandlers` to `URLSessionTask` instances.
    private var taskToHandlersMap: [URLSessionTask: ProgressAndCompletionHandlers?] = [:]
    
    /// The name of the file that is being downloaded.
    private var downloadedFileName: String?

    override public convenience init() {
        // Configure the default URLSessionConfiguration.
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForResource = 300
        sessionConfiguration.waitsForConnectivity = true

        // Create a `OperationQueue` instance for scheduling the delegate calls and completion handlers.
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 3
        queue.qualityOfService = .userInitiated

        self.init(configuration: sessionConfiguration, delegateQueue: queue)
    }

    public init(configuration: URLSessionConfiguration, delegateQueue: OperationQueue) {
        super.init()
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: delegateQueue)
    }

    private func setHandlers(_ handlers: ProgressAndCompletionHandlers?, for task: URLSessionTask) {
        taskToHandlersMap[task] = handlers
    }

    private func getHandlers(for task: URLSessionTask) -> ProgressAndCompletionHandlers? {
        guard let handlers = taskToHandlersMap[task] else {
            return nil
        }

        return handlers
    }

    deinit {
        session.invalidateAndCancel()
        session = nil
    }
}

extension APINetworkSession: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let handlers = getHandlers(for: task) else {
            return
        }

        let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        DispatchQueue.main.async {
            handlers.progress?(progress)
        }
        //  Remove the associated handlers.
        if totalBytesSent == totalBytesExpectedToSend {
            setHandlers(nil, for: task)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard
            let downloadTask = task as? URLSessionDownloadTask,
            let handlers = getHandlers(for: downloadTask)
        else {
            return
        }
        
        DispatchQueue.main.async {
            handlers.completion?(nil, downloadTask.response, downloadTask.error)
        }

        //  Remove the associated handlers.
        setHandlers(nil, for: task)
    }
}

extension APINetworkSession: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard
            let fileName = self.downloadedFileName,
            let handlers = getHandlers(for: downloadTask) else {
            return
        }
        
        // Save the file locally, before it is deleted by the system.
        let tempFileURL = FileHelper().saveFile(at: location, named: fileName)
        
        DispatchQueue.main.async {
            handlers.completion?(tempFileURL, downloadTask.response, downloadTask.error)
        }
        
        //  Remove the associated handlers.
        setHandlers(nil, for: downloadTask)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let handlers = getHandlers(for: downloadTask) else {
            return
        }

        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            handlers.progress?(progress)
        }
    }
}

extension APINetworkSession: NetworkSessionProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask? {
        let session = SharedURLSession.shared.session
        let dataTask = session?.dataTask(with: request) { data, response, error in
            completionHandler(data, response, error)
        }

        return dataTask
    }

    func uploadTask(with request: URLRequest, progressHandler: ProgressHandler?, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask? {
        let uploadTask = session.uploadTask(with: request, from: nil) { data, urlResponse, error in
            completion(data, urlResponse, error)
        }

        // Set the associated progress handler for this task.
        setHandlers((progressHandler, nil), for: uploadTask)
        return uploadTask
    }

    func downloadTask(with request: URLRequest, fileName: String, progressHandler: ProgressHandler?, completion: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask? {
        self.downloadedFileName = fileName
        let downloadTask = session.downloadTask(with: request)
        
        // Set the associated progress and completion handlers for this task.
        setHandlers((progressHandler, completion), for: downloadTask)
        return downloadTask
    }
}
