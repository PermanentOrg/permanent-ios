//
//  ReachabilityManager.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.06.2026.
//

import Foundation
import Network

protocol ReachabilityProviding: AnyObject {
    var isConnected: Bool { get }
}

class ReachabilityManager: ReachabilityProviding {
    static let shared = ReachabilityManager()

    static let reachabilityDidChangeNotifName = Notification.Name("ReachabilityManager.reachabilityDidChangeNotifName")

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "org.permanent.reachabilityMonitor")
    private var isMonitoring = false

    #if DEBUG
    // Set to true to simulate the offline state regardless of the real network path.
    var forceOffline = false {
        didSet {
            guard oldValue != forceOffline else { return }
            NotificationCenter.default.post(name: Self.reachabilityDidChangeNotifName, object: self)
        }
    }
    #endif

    private var pathIsConnected = true

    var isConnected: Bool {
        #if DEBUG
        if forceOffline { return false }
        #endif
        return pathIsConnected
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let isConnected = path.status == .satisfied
                guard isConnected != self.pathIsConnected else { return }
                self.pathIsConnected = isConnected
                NotificationCenter.default.post(name: Self.reachabilityDidChangeNotifName, object: self)
            }
        }
        monitor.start(queue: monitorQueue)
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        monitor.cancel()
    }
}
