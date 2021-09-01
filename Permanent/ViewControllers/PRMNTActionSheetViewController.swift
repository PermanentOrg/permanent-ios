//
//  PRMNTActionSheetViewController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 31.08.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import UIKit

class PRMNTAction {
    let title: String
    let color: UIColor
    let handler: ((PRMNTAction) -> Void)?
    
    init(title: String, color: UIColor = .primary, handler: ((PRMNTAction) -> Void)? = nil) {
        self.title = title
        self.color = color
        self.handler = handler
    }
}

class PRMNTActionSheetViewController: UIViewController {
    
    let actions: [PRMNTAction]
    
    let overlayView = UIView(frame: .zero)
    
    let contentView = UIView(frame: .zero)
    var buttons: [UIButton] = []
    
    var contentViewBottomConstraint: NSLayoutConstraint!

    init(actions: [PRMNTAction]) {
        self.actions = actions
        
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = .darkGray.withAlphaComponent(0.5)
        overlayView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(overlayTapped(_:))))
        view.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        contentView.backgroundColor = .white
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)
        
        contentViewBottomConstraint = contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentViewBottomConstraint
        ])

        actions.forEach { action in
            let button = RoundedButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setup()
            button.configureActionButtonUI(title: action.title, bgColor: action.color)
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)

            contentView.addSubview(button)
            
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
                button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            ])
            
            if let lastButton = buttons.last {
                button.bottomAnchor.constraint(equalTo: lastButton.topAnchor, constant: -8).isActive = true
            } else {
                button.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -8).isActive = true
            }
            
            buttons.append(button)
        }
        
        if let lastButton = buttons.last {
            lastButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16).isActive = true
        } else {
            contentView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
        
        view.layoutIfNeeded()
        contentViewBottomConstraint.constant = contentView.frame.height
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        dismiss(animated: true) { [self] in
            if let index = buttons.firstIndex(of: sender) {
                let action = actions[index]
                action.handler?(action)
            }
        }
    }
    
    @objc func overlayTapped(_ sender: UIGestureRecognizer) {
        dismiss(animated: true)
    }
    
}

extension PRMNTActionSheetViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
}

extension PRMNTActionSheetViewController: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.2
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let toVC = transitionContext.viewController(forKey: .to)
        
        if toVC == self {
            transitionContext.containerView.addSubview(self.view)
            
            overlayView.alpha = 0
            contentViewBottomConstraint.constant = 0
            UIView.animate(withDuration: 0.2) {
                self.overlayView.alpha = 1
                self.view.layoutIfNeeded()
            } completion: { finished in
                transitionContext.completeTransition(true)
            }

        } else {
            contentViewBottomConstraint.constant = contentView.frame.height
            
            UIView.animate(withDuration: 0.2) {
                self.overlayView.alpha = 0
                self.view.layoutIfNeeded()
            } completion: { finished in
                self.view.removeFromSuperview()
                transitionContext.completeTransition(true)
            }

        }
    }
    
}
