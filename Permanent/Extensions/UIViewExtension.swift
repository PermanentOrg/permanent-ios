//  
//  UIViewExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 16.11.2020.
//

import UIKit

extension UIView {
    func enableAutoLayout() {
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func loadNib() {
        Bundle.main.loadNibNamed(
            String(describing: Self.self),
            owner: self,
            options: nil
        )
    }
    
    func setupView(_ view: UIView) {
        addSubview(view)
        
        view.frame = bounds
        view.backgroundColor = .clear
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
}
