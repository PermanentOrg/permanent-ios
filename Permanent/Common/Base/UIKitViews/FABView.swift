//
//  FABView.swift
//  Permanent
//
//  Created by Adrian Creteanu on 20/10/2020.
//

import UIKit

class FABView: UIView {
    fileprivate var plusImageView: UIImageView!
    fileprivate var checklistImageView: UIImageView!
    
    weak var delegate: FABViewDelegate?
    var showsChecklistButton: Bool = false {
        didSet {
            checklistImageView.isHidden = !showsChecklistButton
        }
    }
    
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
        plusImageView.translatesAutoresizingMaskIntoConstraints = false
        
        checklistImageView = UIImageView(image: UIImage(named: "mainChecklistButton"))
        checklistImageView.contentMode = .scaleAspectFit
        checklistImageView.translatesAutoresizingMaskIntoConstraints = false
        checklistImageView.isHidden = true
        
        addSubview(plusImageView)
        addSubview(checklistImageView)
        
        NSLayoutConstraint.activate([
            plusImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            plusImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            plusImageView.widthAnchor.constraint(equalTo: widthAnchor),
            plusImageView.heightAnchor.constraint(equalTo: heightAnchor),
            
            checklistImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            checklistImageView.topAnchor.constraint(equalTo: plusImageView.bottomAnchor, constant: 12),
            checklistImageView.widthAnchor.constraint(equalTo: widthAnchor),
            checklistImageView.heightAnchor.constraint(equalTo: heightAnchor)
        ])
        
        let plusTapGesture = UITapGestureRecognizer(target: self, action: #selector(fabAction))
        plusImageView.isUserInteractionEnabled = true
        plusImageView.addGestureRecognizer(plusTapGesture)
        
        let checklistTapGesture = UITapGestureRecognizer(target: self, action: #selector(checklistAction))
        checklistImageView.isUserInteractionEnabled = true
        checklistImageView.addGestureRecognizer(checklistTapGesture)
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
    
    @objc
    func checklistAction() {
        delegate?.didTapChecklist()
    }
}

protocol FABViewDelegate: AnyObject {
    func didTap()
    func didTapChecklist()
}
