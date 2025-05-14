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
    fileprivate var memberChecklistBanner: UIView!
    fileprivate var arrowView: UIImageView!
    
    weak var delegate: FABViewDelegate?
    var showsChecklistButton: Bool = false {
        didSet {
            checklistImageView.isHidden = !showsChecklistButton
            
            let defaults = UserDefaults.standard
            let bannerWasShown = defaults.bool(forKey: Constants.Keys.StorageKeys.memberChecklistWasShown)
            
            if showsChecklistButton && !bannerWasShown {
                memberChecklistBanner.alpha = 0
                arrowView.alpha = 0
                memberChecklistBanner.isHidden = false
                arrowView.isHidden = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    UIView.animate(withDuration: 0.3, options: .curveEaseInOut) {
                        self.memberChecklistBanner.alpha = 1
                        self.arrowView.alpha = 1
                    } completion: { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            UIView.animate(withDuration: 0.3, options: .curveEaseInOut) {
                                self.memberChecklistBanner.alpha = 0
                                self.arrowView.alpha = 0
                            } completion: { _ in
                                self.memberChecklistBanner.isHidden = true
                                self.arrowView.isHidden = true
                                
                                defaults.set(true, forKey: Constants.Keys.StorageKeys.memberChecklistWasShown)
                            }
                        }
                    }
                }
            } else {
                memberChecklistBanner.isHidden = true
                arrowView.isHidden = true
            }
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
        backgroundColor = .clear
        clipsToBounds = true
        layer.masksToBounds = false
        
        plusImageView = UIImageView(image: UIImage(named: "plus"))
        plusImageView.contentMode = .scaleAspectFit
        plusImageView.translatesAutoresizingMaskIntoConstraints = false
        
        checklistImageView = UIImageView(image: UIImage(named: "mainChecklistButton"))
        checklistImageView.contentMode = .scaleAspectFit
        checklistImageView.translatesAutoresizingMaskIntoConstraints = false
        checklistImageView.isHidden = true
        
        memberChecklistBanner = UIView()
        memberChecklistBanner.translatesAutoresizingMaskIntoConstraints = false
        memberChecklistBanner.layer.cornerRadius = 6
        memberChecklistBanner.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        memberChecklistBanner.isHidden = true
        
        arrowView = UIImageView(image: UIImage(named: "whiteArrowView"))
        arrowView.translatesAutoresizingMaskIntoConstraints = false
        arrowView.contentMode = .scaleAspectFit
        arrowView.isHidden = true
        
        let bannerLabel = UILabel()
        bannerLabel.translatesAutoresizingMaskIntoConstraints = false
        bannerLabel.textColor = UIColor(red: 0.353, green: 0.373, blue: 0.502, alpha: 1)
        bannerLabel.font = UIFont(name: "Usual-Regular", size: 14)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        bannerLabel.attributedText = NSMutableAttributedString(string: "Set up your account", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        memberChecklistBanner.addSubview(bannerLabel)
        
        addSubview(plusImageView)
        addSubview(checklistImageView)
        addSubview(memberChecklistBanner)
        addSubview(arrowView)
        
        NSLayoutConstraint.activate([
            plusImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            plusImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            plusImageView.widthAnchor.constraint(equalTo: widthAnchor),
            plusImageView.heightAnchor.constraint(equalToConstant: 64),
            
            checklistImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            checklistImageView.topAnchor.constraint(equalTo: plusImageView.bottomAnchor, constant: 12),
            checklistImageView.widthAnchor.constraint(equalTo: widthAnchor),
            checklistImageView.heightAnchor.constraint(equalToConstant: 64),
            
            memberChecklistBanner.rightAnchor.constraint(equalTo: checklistImageView.leftAnchor, constant: -16),
            memberChecklistBanner.centerYAnchor.constraint(equalTo: checklistImageView.centerYAnchor),
            memberChecklistBanner.widthAnchor.constraint(equalToConstant: 182),
            memberChecklistBanner.heightAnchor.constraint(equalToConstant: 48),
            
            arrowView.widthAnchor.constraint(equalToConstant: 6),
            arrowView.heightAnchor.constraint(equalToConstant: 12),
            arrowView.leadingAnchor.constraint(equalTo: memberChecklistBanner.trailingAnchor),
            arrowView.centerYAnchor.constraint(equalTo: memberChecklistBanner.centerYAnchor),
            
            bannerLabel.centerXAnchor.constraint(equalTo: memberChecklistBanner.centerXAnchor),
            bannerLabel.centerYAnchor.constraint(equalTo: memberChecklistBanner.centerYAnchor),
            bannerLabel.widthAnchor.constraint(lessThanOrEqualTo: memberChecklistBanner.widthAnchor, constant: -16),
            bannerLabel.heightAnchor.constraint(lessThanOrEqualTo: memberChecklistBanner.heightAnchor, constant: -8)
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
        
        plusImageView.layer.cornerRadius = frame.height / 2
        plusImageView.layer.shadowRadius = 3
        plusImageView.layer.shadowColor = UIColor.black.withAlphaComponent(0.5).cgColor
        plusImageView.layer.shadowOpacity = 1
        plusImageView.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        checklistImageView.layer.cornerRadius = frame.height / 2
        checklistImageView.layer.shadowRadius = 3
        checklistImageView.layer.shadowColor = UIColor.black.withAlphaComponent(0.5).cgColor
        checklistImageView.layer.shadowOpacity = 1
        checklistImageView.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        
        memberChecklistBanner.layer.shadowRadius = 6
        memberChecklistBanner.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        memberChecklistBanner.layer.shadowOpacity = 1
        memberChecklistBanner.layer.shadowOffset = CGSize(width: -2, height: 0)
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
