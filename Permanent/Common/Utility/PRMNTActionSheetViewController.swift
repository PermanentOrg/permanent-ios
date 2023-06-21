//
//  PRMNTActionSheetViewController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 31.08.2021.
//

import UIKit

class PRMNTAction {
    let title: String
    let iconName: String?
    let color: UIColor
    let handler: ((PRMNTAction) -> Void)?
    
    init(title: String, iconName: String? = nil, color: UIColor = .primary, handler: ((PRMNTAction) -> Void)? = nil) {
        self.title = title
        self.iconName = iconName
        self.color = color
        self.handler = handler
    }
}

class PRMNTActionSheetViewController: UIViewController {
    let actions: [PRMNTAction]
    
    let overlayView = UIView(frame: .zero)
    
    let contentView = UIView(frame: .zero)
    var titleLabel: UILabel?
    var buttons: [UIButton] = []
    var titleThumbnail: String?
    
    var contentViewBottomConstraint: NSLayoutConstraint!

    init(title: String? = nil, thumbnail: String? = nil, actions: [PRMNTAction]) {
        self.actions = actions
        
        super.init(nibName: nil, bundle: nil)
        
        self.title = title
        titleThumbnail = thumbnail
        
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
            let button = menuItem(withName: action.title, iconName: action.iconName)
            button.translatesAutoresizingMaskIntoConstraints = false
            
            contentView.addSubview(button)
            
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])
            
            if contentView.subviews.count >= 2 {
                let lastButton = contentView.subviews[contentView.subviews.count - 2]
                button.bottomAnchor.constraint(equalTo: lastButton.topAnchor, constant: -8).isActive = true
            } else {
                button.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -8).isActive = true
            }
        }
        
        if let lastButton = buttons.last {
            let thumbImageView = UIImageView()
            thumbImageView.translatesAutoresizingMaskIntoConstraints = false
            thumbImageView.contentMode = .scaleAspectFit
            thumbImageView.clipsToBounds = true
            
            let titleLabel = UILabel()
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.text = title
            titleLabel.textColor = .white
            titleLabel.font = TextFontStyle.style3.font
            
            let headerView = UIView()
            
            headerView.addSubview(thumbImageView)
            headerView.addSubview(titleLabel)
            
            headerView.translatesAutoresizingMaskIntoConstraints = false
            headerView.backgroundColor = .primary
            
            contentView.addSubview(headerView)
            
            let labelLeadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16)
            
            thumbImageView.sd_setImage(with: URL(string: titleThumbnail)) {image,_,_,_ in
                if image != nil {
                    NSLayoutConstraint.activate([
                        thumbImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                    ])
                    
                    labelLeadingConstraint.constant = 54
                }
            }
            
            NSLayoutConstraint.activate([
                thumbImageView.widthAnchor.constraint(equalToConstant: 30),
                headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
                headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
                headerView.bottomAnchor.constraint(equalTo: lastButton.topAnchor, constant: -8),
                headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
                headerView.heightAnchor.constraint(equalToConstant: 50),
                labelLeadingConstraint,
                titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
                titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 0),
                thumbImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                thumbImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 0)
            ])
            
            view.layoutIfNeeded()
            contentViewBottomConstraint.constant = contentView.frame.height
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func menuItem(withName name: String, iconName: String?) -> UIView {
        let imageView = UIImageView(image: iconName != nil ? UIImage(named: iconName!) : .placeholder)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .black
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 30)
        ])
        
        let nameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 20))
        nameLabel.text = name
        nameLabel.font = TextFontStyle.style7.font
        
        let itemStackView = UIStackView(arrangedSubviews: [imageView, nameLabel])
        itemStackView.axis = .horizontal
        itemStackView.spacing = 8
        itemStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let containerView = UIView()
        containerView.addSubview(itemStackView)
        
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        buttons.append(button)
        containerView.addSubview(button)
        
        NSLayoutConstraint.activate([
            itemStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            itemStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            itemStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            itemStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0),
            button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            button.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0)
        ])
        
        return containerView
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
