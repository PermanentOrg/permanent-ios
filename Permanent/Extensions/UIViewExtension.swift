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
        delay: TimeInterval = 0.0,
        usingSpringWithDamping damping: CGFloat = 0.8,
        options: AnimationOptions = .curveEaseInOut,
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        UIView.animate(
            withDuration: duration,
            delay: delay,
            usingSpringWithDamping: damping,
            initialSpringVelocity: 0,
            options: options,
            animations: animations,
            completion: completion
        )
    }
    
    func presentPopup(_ popupView: UIView?, overlayView: UIView?) {
        UIView.animate(animations: {
            popupView?.frame = self.bounds
            overlayView?.alpha = 0.5
        })
    }
    
    func dismissPopup(_ popupView: UIView?, overlayView: UIView?, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(animations: {
            popupView?.frame = CGRect(origin: CGPoint(x: 0, y: self.bounds.height), size: self.bounds.size)
            overlayView?.alpha = 0.0
        }, completion: completion)
    }
    
    func showNotificationBanner(height: CGFloat = Constants.Design.bannerHeight, title: String) {
        let initialBannerOrigin = CGPoint(x: 0, y: -height)
        let bannerView = UIView(frame: CGRect(origin: initialBannerOrigin,
                                              size: CGSize(width: self.bounds.width, height: height)))
        
        bannerView.backgroundColor = .paleGreen
        self.addSubview(bannerView)
        
        let messageLabel = UILabel() // UILabel(frame: CGRect(origin: bannerView.center, size: CGSize(width: self.bounds.width, height: height / 2)))
        messageLabel.text = title
        messageLabel.textColor = .bilbaoGreen
        messageLabel.font = Text.style17.font
        
        bannerView.addSubview(messageLabel)
        messageLabel.enableAutoLayout()
        NSLayoutConstraint.activate([
            messageLabel.centerXAnchor.constraint(equalTo: bannerView.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: bannerView.centerYAnchor)
        ])
        
        UIView.animate(animations: {
            bannerView.frame.origin = CGPoint(x: 0, y: 0)
        }, completion: { _ in
        
            UIView.animate(delay: 0.5,
                           animations: {
                               bannerView.frame.origin = initialBannerOrigin
                           }, completion: { _ in
                               bannerView.removeFromSuperview()
                           })
        })
    }
    
    static func tableViewBgView(withTitle title: String) -> UIView {
        let bgView = UIView()
        bgView.backgroundColor = .backgroundPrimary
        
        let noSharesLabel = UILabel()
        noSharesLabel.font = Text.style8.font
        noSharesLabel.textColor = .textPrimary
        noSharesLabel.text = title
        
        bgView.addSubview(noSharesLabel)
        noSharesLabel.enableAutoLayout()
        NSLayoutConstraint.activate([
            noSharesLabel.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 5),
            noSharesLabel.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 20)
        ])
        
        return bgView
    }
    
    // MARK: - Auto Layout
    
    func constraintToSquare(_ side: CGFloat) {
        self.widthAnchor.constraint(equalToConstant: side).isActive = true
        self.heightAnchor.constraint(equalToConstant: side).isActive = true
    }
}

extension UIView {
    func addBlur(styled blurStyle: UIBlurEffect.Style = .light) {
        let backView = UIView(frame: self.bounds)
        backView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        self.addSubview(backView)
        
        let blurEffect = UIBlurEffect(style: blurStyle)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.isUserInteractionEnabled = false
        addSubview(blurEffectView)
    }
    
    func removeBlurIfNeeded() {
        guard self.subviews.last is UIVisualEffectView else {
            return
        }
        
        // We have to remove the blur view, and the view underneath it (backView).
        // See `addBlur` method.
        for _ in 0 ..< 2 {
            self.subviews.last?.removeFromSuperview()
        }
    }
    
    func hideKeyboard() {
        self.endEditing(true)
    }
}
