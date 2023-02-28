//
//  FABTagsManagementActionSheet.swift
//  Permanent
//
//  Created by Lucian Cerbu on 20.02.2023.
//

import Foundation
import UIKit


class FABTagsManagementActionSheet: BaseViewController<ManageTagsViewModel> {
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var headerTitleLabel: UILabel!
    
    
    @IBOutlet weak var tagNameLabel: UILabel!
    @IBOutlet weak var cancelButton: RoundedButton!
    @IBOutlet weak var rightBottomButton: RoundedButton!
    @IBOutlet weak var tagNameTextField: UITextField!
    
    @IBOutlet weak var contentViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    
    enum MenuType: String {
        case newTag
        case editTag
    }
    
    var menuType: MenuType!
    var index: Int?
    
    let overlayView = UIView(frame: .zero)
    private var initialCenter: CGPoint = .zero
    private var scrollViewInitialHeight: CGFloat = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .clear
        loadOverlay()
        loadHeader()
        initContentItems()
        initButtonsUI()
    }
    
    func loadOverlay() {
        contentView.backgroundColor = .darkGray.withAlphaComponent(0.5)
    }
    
    func loadHeader() {
        headerView.layer.cornerRadius = 12
        headerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        headerView.backgroundColor = .darkBlue
    
        headerImageView.image = UIImage(named: "tagsBorder")?.withRenderingMode(.alwaysTemplate)
        headerImageView.tintColor = .white
        headerImageView.contentMode = .scaleAspectFill

        switch menuType {
        case .newTag:
            headerTitleLabel.text = "New tag".localized()
        case .editTag:
            headerTitleLabel.text = "Edit tag".localized()
        default:
            headerTitleLabel.text = ""
        }
        
        headerTitleLabel.textColor = .white
        headerTitleLabel.font = Text.style32.font
        headerTitleLabel.setTextSpacingBy(value: -0.16)
        
        topBarView.alpha = 0.5
        topBarView.backgroundColor = .white
        topBarView.layer.cornerRadius = 2
    }
    
    func initContentItems() {
        tagNameLabel.text = "Tag Name".uppercased().localized()
        tagNameLabel.font = Text.style43.font
        tagNameLabel.textColor = .gray
        
        tagNameTextField.placeholder = "Tag name...".localized()
        tagNameTextField.font = Text.style39.font
        tagNameTextField.textColor = .darkBlue
        tagNameTextField.layer.backgroundColor = UIColor(red: 0.957, green: 0.965, blue: 0.992, alpha: 0.5).cgColor
        tagNameTextField.layer.cornerRadius = 2
        tagNameTextField.layer.borderWidth = 1
        tagNameTextField.layer.borderColor = UIColor(red: 0.957, green: 0.965, blue: 0.992, alpha: 1).cgColor
        
        if menuType == .editTag, let index = self.index, let tagName = viewModel?.getTagNameFromIndex(index: index) {
            tagNameTextField.text = tagName
        }
    }
    
    func initButtonsUI() {
        let rightButtonLabelText = menuType == .newTag ? "Add tag".localized() : "Save".localized()
        
        cancelButton.bgColor = .whiteGray
        cancelButton.setAttributedTitle(NSAttributedString(string: "Cancel".localized(), attributes: [.font: Text.style11.font, .foregroundColor: UIColor.darkBlue]), for: .normal)
        cancelButton.setAttributedTitle(NSAttributedString(string: "Cancel".localized(), attributes: [.font: Text.style11.font, .foregroundColor: UIColor.darkBlue]), for: .highlighted)
        cancelButton.layer.cornerRadius = 1
        
        rightBottomButton.bgColor = .darkBlue
        rightBottomButton.setAttributedTitle(NSAttributedString(string: rightButtonLabelText, attributes: [.font: Text.style8.font, .foregroundColor: UIColor.white]), for: .normal)
        rightBottomButton.setAttributedTitle(NSAttributedString(string: rightButtonLabelText, attributes: [.font: Text.style8.font, .foregroundColor: UIColor.white]), for: .highlighted)
        rightBottomButton.layer.cornerRadius = 1
    }
    
    // MARK: - Actions    
    @IBAction func cancelButtonAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func rightBottomButtonAction(_ sender: Any) {
        switch menuType {
        case .newTag:
            if let isNewTagNameValid = viewModel?.isNewTagNameValid(withText: tagNameTextField.text), isNewTagNameValid {
                viewModel?.addTagToArchive(withName: tagNameTextField.text, completion: { error in
                    if let _ = error {
                        self.showAlert(title: .error, message: .errorMessage)
                    } else {
                        self.dismiss(animated: true)
                    }
                })
            } else {
                self.showAlert(title: .error, message: "Enter a valid Tag Name".localized())
            }
            
        case .editTag:
            if let index = self.index, let isNewTagNameValid = viewModel?.isNewTagNameValid(withText: tagNameTextField.text), isNewTagNameValid  {
                viewModel?.updateTagName(newTagName: tagNameTextField.text, index: index, completion: { error in
                    if let _ = error {
                        self.showAlert(title: .error, message: .errorMessage)
                    } else {
                        self.dismiss(animated: true)
                    }
                })
            } else {
                self.showAlert(title: .error, message: "Enter a valid Tag Name".localized())
            }
        default:
            break
        }
    }
    
    // MARK: - Keyboard
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyBoardInfo = notification.userInfo,
              let endFrame = keyBoardInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else { return }
        
        let keyBoardFrameHeight = endFrame.cgRectValue.height
        
        contentViewTopConstraint.constant = -(contentViewHeightConstraint.constant + keyBoardFrameHeight)
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        contentViewTopConstraint.constant = -contentViewHeightConstraint.constant
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
}

extension FABTagsManagementActionSheet: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
}

extension FABTagsManagementActionSheet: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.2
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let toVC = transitionContext.viewController(forKey: .to)

        if toVC == self {
            transitionContext.containerView.addSubview(self.view)

            overlayView.alpha = 0
            contentViewTopConstraint.constant = -contentViewHeightConstraint.constant
            UIView.animate(withDuration: 0.2) {
                self.contentView.alpha = 1
                self.view.layoutIfNeeded()
            } completion: { finished in
                transitionContext.completeTransition(true)
            }
        } else {
            contentViewTopConstraint.constant = contentView.frame.height
            UIView.animate(withDuration: 0.2) {
                self.contentView.alpha = 0
                self.view.layoutIfNeeded()
            } completion: { finished in
                self.view.removeFromSuperview()
                transitionContext.completeTransition(true)
            }
        }
    }
}

extension FABTagsManagementActionSheet: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        rightBottomButtonAction(self)
    }
}
