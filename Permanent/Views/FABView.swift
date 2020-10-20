//
//  FABView.swift
//  Permanent
//
//  Created by Adrian Creteanu on 20/10/2020.
//

import UIKit

class FABView: UIView {
    fileprivate var plusImageView: UIImageView!
    
    weak var delegate: FABViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .backgroundPrimary
        clipsToBounds = true
        layer.masksToBounds = false
        
        plusImageView = UIImageView(image: UIImage(named: "plus"))
        plusImageView.contentMode = .scaleAspectFit
        
        addSubview(plusImageView)
        NSLayoutConstraint.activate([
            plusImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            plusImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            plusImageView.widthAnchor.constraint(equalTo: widthAnchor),
            plusImageView.heightAnchor.constraint(equalTo: heightAnchor)
        ])
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(fabAction)))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = frame.height / 2
        layer.shadowRadius = 3
        layer.shadowColor = UIColor.black.withAlphaComponent(0.5).cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = CGSize(width: 0, height: 0)
    }
    
    // MARK: - Actions
    
    @objc
    func fabAction() {
        delegate?.didTap()
    }
}

protocol FABViewDelegate: class {
    func didTap()
}
