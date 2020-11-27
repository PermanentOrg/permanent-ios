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
    
    static func animate(
        withDuration duration: TimeInterval = 0.5,
        usingSpringWithDamping damping: CGFloat = 0.8,
        options: AnimationOptions = .curveEaseInOut,
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: damping,
            initialSpringVelocity: 0,
            options: options,
            animations: animations,
            completion: completion
        )
        
    }
    
    func presentPopup(_ popupView: UIView?, overlayView: UIView) {
        UIView.animate(animations: {
            popupView?.frame = self.bounds
            overlayView.alpha = 0.5
        })
    }
    
    func dismissPopup(_ popupView: UIView?, overlayView: UIView, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(animations: {
            popupView?.frame = CGRect(origin: CGPoint(x: 0, y: self.bounds.height), size: self.bounds.size)
            overlayView.alpha = 0.0
        }, completion: completion)
    }
}
