//
//  AddButtonMenuViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.09.2023.

import UIKit

class AddButtonMenuViewController: UIViewController {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        menuBottomConstraints.constant = 0
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func initUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.26)
        
        view.layer.masksToBounds = false
        view.layer.shadowRadius = 4
        view.layer.shadowColor = UIColor.black.withAlphaComponent(0.26).cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        menuBackgroundView.layer.cornerRadius = 32
        separatorHeightConstrait.constant = 1/UIScreen.main.scale
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touchView = touches.first?.view else { return }
        if touchView == self.view {
            menuBottomConstraints.constant = -500
            
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            } completion: { _ in
                NotificationCenter.default.post(name: Self.addButtonMenuDismissView, object: self, userInfo: ["showMenu": false])
                self.dismiss(animated: false)
            }
        }
    }
    
    @IBAction func anyButtonTapped(_ sender: Any) {
        menuBottomConstraints.constant = -500
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.dismiss(animated: false)
        }
    }
}
