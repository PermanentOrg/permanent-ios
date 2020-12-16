//  
//  UITableViewCellExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14.12.2020.
//

import UIKit

extension UITableView {
    
    public func register<T: UITableViewCell>(cellClass: T.Type) {
        register(cellClass, forCellReuseIdentifier: cellClass.reuseIdentifier)
    }
    
    public func registerNib<T: UITableViewCell>(cellClass: T.Type) {
        let nib = UINib(nibName: cellClass.reuseIdentifier, bundle: nil)
        register(nib, forCellReuseIdentifier: cellClass.reuseIdentifier)
    }
    
    public func dequeue<T: UITableViewCell>(cellClass: T.Type) -> T? {
        return dequeueReusableCell(withIdentifier: cellClass.reuseIdentifier) as? T
    }
    
    public func dequeue<T: UITableViewCell>(cellClass: T.Type, forIndexPath indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(
                withIdentifier: cellClass.reuseIdentifier, for: indexPath) as? T else {
            fatalError(
                "Error: cell with id: \(cellClass.reuseIdentifier) for indexPath: \(indexPath) is not \(T.self)")
        }
        return cell
    }
}

extension UITableViewCell {
    static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
}
