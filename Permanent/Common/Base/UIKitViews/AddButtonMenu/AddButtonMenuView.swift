//
//  AddButtonMenuView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.09.2023.

import UIKit

class AddButtonMenuView: UIView {
    @IBOutlet weak var menuBackgroundView: UIView!
    @IBOutlet weak var menuBottomConstraints: NSLayoutConstraint!
    @IBOutlet weak var createNewFolderBtn: UIButton!
    @IBOutlet weak var takePhotoVideoBtn: UIButton!
    @IBOutlet weak var uploadPhotosFromLibraryBtn: UIButton!
    @IBOutlet weak var uploadAlbumBtn: UIButton!
    @IBOutlet weak var createEventAlbumBtn: UIButton!
    @IBOutlet weak var browseFilesBtn: UIButton!
    @IBOutlet weak var separatorHeightConstrait: NSLayoutConstraint!
    
    static let addButtonMenuDismissView = NSNotification.Name("AddButtonMenuView.dismissView")
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup(frame: CGRect(x: 0, y: -100, width: frame.width, height: frame.height + 100))
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if point.y < 0 {
            NotificationCenter.default.post(name: Self.addButtonMenuDismissView, object: self, userInfo: ["showMenu": false])
        }
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, touch.view == self {
            NotificationCenter.default.post(name: Self.addButtonMenuDismissView, object: self, userInfo: ["showMenu": false])
        }
    }
    
    func xibSetup(frame: CGRect) {
        let view = loadXib()
        view.frame = frame
        view.backgroundColor = UIColor.black.withAlphaComponent(0.26)
        
        view.layer.masksToBounds = false
        view.layer.shadowRadius = 4
        view.layer.shadowColor = UIColor.black.withAlphaComponent(0.26).cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        initUI()
        
        addSubview(view)

        menuBottomConstraints.constant = 60 + 32
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
    
    func initUI() {
        menuBackgroundView.layer.cornerRadius = 32
        separatorHeightConstrait.constant = 1/UIScreen.main.scale
    }
    
    func loadXib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "AddButtonMenuView", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return UIView() }
        return view
    }
}
