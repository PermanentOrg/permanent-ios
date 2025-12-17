//
//  WorkspaceControllerCache.swift
//  Permanent
//
//  Created on 17.12.2025.
//

import UIKit

/// Caches workspace view controllers for instant switching
/// Invalidates on archive change to ensure fresh data
class WorkspaceControllerCache {
    static let shared = WorkspaceControllerCache()
    
    private var cache: [String: UIViewController] = [:]
    private let maxCacheSize = 3
    
    private init() {
        // Listen for archive changes to invalidate cache
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(archiveDidChange),
            name: ArchivesViewModel.didChangeArchiveNotification,
            object: nil
        )
        
        // Clear on memory warning
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearAll),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    private func cacheKey(workspace: WorkspaceType, archiveId: Int) -> String {
        return "\(workspace.rawValue)_\(archiveId)"
    }
    
    func get(workspace: WorkspaceType, archiveId: Int) -> UIViewController? {
        let key = cacheKey(workspace: workspace, archiveId: archiveId)
        return cache[key]
    }
    
    func set(_ controller: UIViewController, workspace: WorkspaceType, archiveId: Int) {
        let key = cacheKey(workspace: workspace, archiveId: archiveId)
        cache[key] = controller
        
        // Enforce max cache size
        if cache.count > maxCacheSize {
            if let firstKey = cache.keys.first {
                cache.removeValue(forKey: firstKey)
            }
        }
    }
    
    func invalidateForArchive(_ archiveId: Int) {
        cache = cache.filter { !$0.key.hasSuffix("_\(archiveId)") }
    }
    
    @objc func clearAll() {
        cache.removeAll()
    }
    
    @objc private func archiveDidChange() {
        clearAll()
    }
}
