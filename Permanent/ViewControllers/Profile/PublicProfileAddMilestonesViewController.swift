//
//  PublicProfileAddMilestonesViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.02.2022.
//

import UIKit
import GoogleMaps
import CoreLocation

class PublicProfileAddMilestonesViewController: BaseViewController<PublicProfilePageViewModel> {
    var milestone: MilestoneProfileItem?
    var isNewItem: Bool {
        return milestone == nil ? true : false
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var titleHintLabel: UILabel!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var startDateTextField: UITextField!
    @IBOutlet weak var startDateHintLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var endDateTextField: UITextField!
    @IBOutlet weak var endDateHintLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var descriptionHintLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var locationHintLabel: UILabel!
    @IBOutlet weak var mapView: UIView!
    
    var map: GMSMapView!
    var marker: GMSMarker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        initUI()
        
        titleTextField.delegate = self
        startDateTextField.delegate = self
        endDateTextField.delegate = self
        descriptionTextField.delegate = self
        locationTextField.delegate = self
        
        addDismissKeyboardGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    
        view.endEditing(true)
    }
    
    func initUI() {
        title = isNewItem ? "Add Milestone".localized() : "Edit Milestone".localized()
        let titleLabels = [titleLabel, startDateLabel, endDateLabel, descriptionLabel, locationLabel]
        let textFields = [titleTextField, startDateTextField, endDateTextField, descriptionTextField, locationTextField]
        let hintLabels = [titleHintLabel, startDateHintLabel, endDateHintLabel, descriptionHintLabel, locationHintLabel]
        
        for label in titleLabels {
            label?.textColor = .middleGray
            label?.font = Text.style12.font
        }
        
        for textField in textFields {
            textField?.layer.borderColor = UIColor.lightGray.cgColor
            textField?.layer.borderWidth = 0.5
            textField?.layer.cornerRadius = 3
            textField?.textColor = .middleGray
            textField?.font = Text.style7.font
        }
        
        for label in hintLabels {
            label?.textColor = .lightGray
            label?.font = Text.style8.font
            label?.textAlignment = .left
        }
        
        titleLabel.text = "\(ProfilePageData.milestoneTitle()) (<COUNT>/140)".localized().replacingOccurrences(of: "<COUNT>", with: "\(milestone?.title?.count ?? 0)")
        startDateLabel.text = ProfilePageData.milestoneStartDate()
        endDateLabel.text = ProfilePageData.milestoneEndDate()
        descriptionLabel.text = "\(ProfilePageData.milestoneDescription())(<COUNT>/200)".localized().replacingOccurrences(of: "<COUNT>", with: "\(milestone?.description?.count ?? 0)")
        locationLabel.text = ProfilePageData.milestoneLocation()
        
        titleHintLabel.text = ProfilePageData.milestoneTitleHint()
        startDateHintLabel.text = ProfilePageData.milestoneStartDateHint()
        endDateHintLabel.text = ProfilePageData.milestoneEndDateHint()
        descriptionHintLabel.text = ProfilePageData.milestoneDescriptionHint()
        locationHintLabel.text = ProfilePageData.milestoneLocationHint()
    }
    
    func setupNavigationBar() {
        styleNavBar()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeButtonAction(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction(_:)))
    }
    
    @objc func closeButtonAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @objc func doneButtonAction(_ sender: Any) {
        dismiss(animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension PublicProfileAddMilestonesViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case titleTextField:
            titleHintLabel.isHidden = true
            
        case startDateTextField:
            startDateHintLabel.isHidden = true
            
        case endDateTextField:
            endDateHintLabel.isHidden = true
            
        case descriptionTextField:
            descriptionHintLabel.isHidden = true
            
        case locationTextField:
            locationHintLabel.isHidden = true
            
        default:
            return
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text else { return false }
        let textCount = textFieldText.count + string.count - range.length
        
        switch textField {
        case titleTextField:
            titleLabel.text = "\(ProfilePageData.milestoneTitle()) (<COUNT>/140)".localized().replacingOccurrences(of: "<COUNT>", with: "\(textCount)")
            
            if textCount < 140 {
                return true
            }
            return false
            
        case descriptionTextField:
            descriptionLabel.text = "\(ProfilePageData.milestoneDescription())(<COUNT>/200)".localized().replacingOccurrences(of: "<COUNT>", with: "\(textCount)")
            
            if textCount < 200 {
                return true
            }
            return false
            
        default:
            return true
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let textFieldText = textField.text else { return }
        
        switch textField {
        case titleTextField:
            if textFieldText.isEmpty {
                titleHintLabel.isHidden = false
            }
            
        case startDateTextField:
            if textFieldText.isEmpty {
                startDateHintLabel.isHidden = false
            }
            
        case endDateTextField:
            if textFieldText.isEmpty {
                endDateHintLabel.isHidden = false
            }
            
        case descriptionTextField:
            if textFieldText.isEmpty {
                descriptionHintLabel.isHidden = false
            }
            
        case locationTextField:
            if textFieldText.isEmpty {
                locationHintLabel.isHidden = false
            }
        
        default:
            return
        }
    }
}
