//
//  BannerView.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 06.06.2023.

import UIKit

class BannerView: UIView {
    
    var action: (() -> Void)?
    var dismissAction: (() -> Void)?
    
    private var type: BannerType = .legacy {
        didSet {
            icon.image = type.icon
            title.text = type.title
            subtitle.text = type.subtitle
        }
    }
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    @IBAction func dismiss(_ sender: Any) {
        type.didShowBanner()
        dismissAction?()
    }
    
    @IBAction func tryNow(_ sender: Any) {
        type.didShowBanner()
        action?()
    }
    
    convenience init(type: BannerType) {
        self.init(frame: .zero)
        
        commonInit()
        
        self.type = type
    }
    
    private func commonInit(positionOffset: CGPoint = CGPoint(x: 0.0, y: 0.0)) {
        loadNib()
        setupView(contentView, positionOffset: positionOffset)
    }
}
