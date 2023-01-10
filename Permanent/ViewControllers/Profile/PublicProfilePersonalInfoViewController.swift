//
//  PublicProfilePersonalInfoViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.12.2021.
//

import UIKit
import GoogleMaps
import CoreLocation

class PublicProfilePersonalInfoViewController: BaseViewController<PublicProfilePageViewModel> {
    @IBOutlet weak var fullNameTitleLabel: UILabel!
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var nicknameTitleLabel: UILabel!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var genderTitleLabel: UILabel!
    @IBOutlet weak var genderTextField: UITextField!
    @IBOutlet weak var birthDateTitleLabel: UILabel!
    @IBOutlet weak var birthDateTextField: UITextField!
    @IBOutlet weak var locationTitleLabel: UILabel!
    @IBOutlet weak var locationTextField: UITextField!
    
    let datePicker = UIDatePicker()
    
    @IBOutlet weak var genderItemsView: UIView!
    @IBOutlet weak var mapView: UIView!
    
    var map: GMSMapView!
    var marker: GMSMarker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        initUI()
        
        fullNameTextField.delegate = self
        nicknameTextField.delegate = self
        genderTextField.delegate = self
        birthDateTextField.delegate = self
        locationTextField.delegate = self
        
        setFieldValues()
        initMapView()
        
        addDismissKeyboardGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    
        view.endEditing(true)
    }
    
    func setupNavigationBar() {
        styleNavBar()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeButtonAction(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction(_:)))
    }
    
    func initUI() {
        title = viewModel?.archiveType.personalInformationPublicPageTitle
        
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        
        fullNameTitleLabel.textColor = .middleGray
        fullNameTitleLabel.font = Text.style12.font
        
        fullNameTextField.layer.borderColor = UIColor.lightGray.cgColor
        fullNameTextField.layer.borderWidth = 0.5
        fullNameTextField.layer.cornerRadius = 3
        fullNameTextField.textColor = .middleGray
        fullNameTextField.font = Text.style7.font
        
        nicknameTitleLabel.textColor = .middleGray
        nicknameTitleLabel.font = Text.style12.font
        
        nicknameTextField.layer.borderColor = UIColor.lightGray.cgColor
        nicknameTextField.layer.borderWidth = 0.5
        nicknameTextField.layer.cornerRadius = 3
        nicknameTextField.textColor = .middleGray
        nicknameTextField.font = Text.style7.font
        
        genderTitleLabel.textColor = .middleGray
        genderTitleLabel.font = Text.style12.font
        
        genderTextField.layer.borderColor = UIColor.lightGray.cgColor
        genderTextField.layer.borderWidth = 0.5
        genderTextField.layer.cornerRadius = 3
        genderTextField.textColor = .middleGray
        genderTextField.font = Text.style7.font
        
        birthDateTitleLabel.textColor = .middleGray
        birthDateTitleLabel.font = Text.style12.font
        
        birthDateTextField.layer.borderColor = UIColor.lightGray.cgColor
        birthDateTextField.layer.borderWidth = 0.5
        birthDateTextField.layer.cornerRadius = 3
        birthDateTextField.textColor = .middleGray
        birthDateTextField.font = Text.style7.font
        
        locationTitleLabel.textColor = .middleGray
        locationTitleLabel.font = Text.style12.font
        
        locationTextField.layer.borderColor = UIColor.lightGray.cgColor
        locationTextField.layer.borderWidth = 0.5
        locationTextField.layer.cornerRadius = 3
        locationTextField.textColor = .middleGray
        locationTextField.font = Text.style7.font
        
        if let archiveType = viewModel?.archiveType {
            fullNameTitleLabel.text = "\(ProfilePageData.nameTitle(archiveType: archiveType)) (<COUNT>/120)".localized().replacingOccurrences(of: "<COUNT>", with: "\(viewModel?.basicProfileItem?.fullName?.count ?? 0)")
            nicknameTitleLabel.text = "\(ProfilePageData.nickNameTitle(archiveType: archiveType)) (<COUNT>/120)".localized().replacingOccurrences(of: "<COUNT>", with: "\(viewModel?.basicProfileItem?.nickname?.count ?? 0)")
            genderTitleLabel.text = ProfilePageData.genderTitle(archiveType: archiveType)
            birthDateTitleLabel.text = ProfilePageData.birthDateTitle(archiveType: archiveType)
            locationTitleLabel.text = ProfilePageData.birthLocationTitle(archiveType: archiveType)
            
            fullNameTextField.placeholder = ProfilePageData.nameHint(archiveType: archiveType)
            nicknameTextField.placeholder = ProfilePageData.nickNameHint(archiveType: archiveType)
            genderTextField.placeholder = ProfilePageData.genderHint(archiveType: archiveType)
            birthDateTextField.placeholder = ProfilePageData.birthDateHint(archiveType: archiveType)
            locationTextField.placeholder = ProfilePageData.birthLocationHint(archiveType: archiveType)
            
            if archiveType == .organization || archiveType == .family {
                genderItemsView.isHidden = true
            }
        }
        setupDatePicker()
    }
    
    func initMapView() {
        let camera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 9.9)
        map = GMSMapView.map(withFrame: mapView.bounds, camera: camera)
        map.isUserInteractionEnabled = false
        map.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.addSubview(map)
        
        let locationDetails = getLocationDetails()
        mapView.isHidden = locationDetails == (0, 0)
        
        setLocation(locationDetails.latitude, locationDetails.longitude)
    }
    
    func setLocation(_ latitude: Double, _ longitude: Double) {
        let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        
        map.moveCamera(GMSCameraUpdate.setTarget(coordinate, zoom: 9.9))

        if marker == nil {
            marker = GMSMarker()
        }
        marker.position = coordinate
        marker.map = map
    }
    
    @objc func closeButtonAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @objc func doneButtonAction(_ sender: Any) {
        var publicProfileUpdateIsSuccessfully: (Bool, Bool, Bool) = (false, false, false)
        
        let group = DispatchGroup()
        
        showSpinner()
        
        group.enter()
        group.enter()
        group.enter()
        viewModel?.updateBasicProfileItem(fullNameNewValue: fullNameTextField.text, nicknameNewValue: nicknameTextField.text, { result in
            publicProfileUpdateIsSuccessfully.0 = result
            group.leave()
        })

        viewModel?.updateGenderProfileItem(genderNewValue: genderTextField.text, { result in
            publicProfileUpdateIsSuccessfully.1 = result
            group.leave()
        })
        if let archiveType = viewModel?.archiveType {
            if archiveType == .person {
                viewModel?.updateBirthInfoProfileItem(birthDateNewValue: birthDateTextField.text, { result in
                    publicProfileUpdateIsSuccessfully.2 = result
                    group.leave()
                })
            } else {
                viewModel?.updateEstablishedInfoProfileItem(newValue: birthDateTextField.text, { result in
                    publicProfileUpdateIsSuccessfully.2 = result
                    group.leave()
                })
            }
        }
        group.notify(queue: DispatchQueue.main) {
            self.hideSpinner()
            if publicProfileUpdateIsSuccessfully == (true, true, true) {
                self.dismiss(animated: true)
            } else {
                self.showAlert(title: .error, message: .errorMessage)
            }
        }
    }
    
    func setFieldValues() {
        guard let archiveType = viewModel?.archiveType else { return }
        
        fullNameTextField.text = viewModel?.basicProfileItem?.fullName
        nicknameTextField.text = viewModel?.basicProfileItem?.nickname
        genderTextField.text = viewModel?.profileGenderProfileItem?.personGender
        
        if archiveType == .person {
            birthDateTextField.text = viewModel?.birthInfoProfileItem?.birthDate
            locationTextField.text = viewModel?.birthInfoProfileItem?.birthLocationFormated
        } else {
            birthDateTextField.text = viewModel?.establishedInfoProfileItem?.establishedDate
            locationTextField.text = viewModel?.establishedInfoProfileItem?.establishedLocationFormated
        }
    }
    
    func setupDatePicker() {
        let dateFormatter = DateFormatter()
        var date = dateFormatter.date(from: "")
        dateFormatter.timeZone = .init(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let archiveType = viewModel?.archiveType {
            if archiveType == .person {
                date = dateFormatter.date(from: viewModel?.birthInfoProfileItem?.birthDate ?? "")
            } else {
                date = dateFormatter.date(from: viewModel?.establishedInfoProfileItem?.establishedDate ?? "")
            }
        }
        
        datePicker.date = date ?? Date()
        datePicker.addTarget(self, action: #selector(datePickerDidChange(_:)), for: .valueChanged)
        datePicker.datePickerMode = .date
        datePicker.maximumDate = Date()
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.sizeToFit()
        
        let doneContainerView = UIView(frame: CGRect(x: 0, y: 0, width: datePicker.frame.width, height: 40))
        let doneButton = RoundedButton(frame: CGRect(x: datePicker.frame.width - 92, y: 0, width: 90, height: doneContainerView.frame.height))
        doneButton.autoresizingMask = [.flexibleLeftMargin]
        doneButton.setup()
        doneButton.setFont(UIFont.systemFont(ofSize: 17))
        doneButton.configureActionButtonUI(title: "done", bgColor: .systemBlue)
        doneButton.addTarget(self, action: #selector(datePickerDoneButtonPressed(_:)), for: .touchUpInside)
        doneContainerView.addSubview(doneButton)
        
        let stackView = UIStackView(arrangedSubviews: [datePicker, doneContainerView])
        stackView.axis = .vertical
        stackView.frame = CGRect(x: 0, y: 0, width: datePicker.frame.width, height: datePicker.frame.height + doneContainerView.frame.height + 40)
        
        birthDateTextField.inputView = stackView
    }
    
    @objc func datePickerDoneButtonPressed(_ sender: Any) {
        let date = datePicker.date

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        birthDateTextField.text = dateFormatter.string(from: date)
        
        birthDateTextField.resignFirstResponder()
    }
    
    @objc func datePickerDidChange(_ sender: UIDatePicker) {
        let date = sender.date
    
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        birthDateTextField.text = dateFormatter.string(from: date)
    }
    
    func getLocationDetails() -> (latitude: Double, longitude: Double) {
        if let archiveType = viewModel?.archiveType {
            switch archiveType {
            case .person:
                if let latitude = viewModel?.birthInfoProfileItem?.birthLocation?.latitude,
                    let longitude = viewModel?.birthInfoProfileItem?.birthLocation?.longitude {
                    return (latitude, longitude)
                } else {
                    return (0, 0)
                }
                
            case .family, .organization, .nonProfit:
                if let latitude = viewModel?.establishedInfoProfileItem?.establishedLocation?.latitude,
                    let longitude = viewModel?.establishedInfoProfileItem?.establishedLocation?.longitude {
                    return (latitude, longitude)
                } else {
                    return (0, 0)
                }
            }
        }
        return (0, 0)
    }
}

extension PublicProfilePersonalInfoViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard textField == locationTextField else { return }
        
        let locationSetVC = UIViewController.create(withIdentifier: .locationSetOnTap, from: .profile) as! PublicProfileLocationSetViewController
        locationSetVC.delegate = self
        locationSetVC.viewModel = viewModel
        
        if let archiveType = viewModel?.archiveType {
            locationSetVC.locnVO = archiveType == .person ? viewModel?.birthInfoProfileItem?.locnVOs?.first : viewModel?.establishedInfoProfileItem?.locnVOs?.first
        }
        
        let navigationVC = NavigationController(rootViewController: locationSetVC)
        navigationVC.modalPresentationStyle = .fullScreen
        present(navigationVC, animated: true)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text,
            let archiveType = viewModel?.archiveType else { return false }
        let textCount = textFieldText.count + string.count - range.length
        
        switch textField {
        case fullNameTextField:
            fullNameTitleLabel.text = "\(ProfilePageData.nameTitle(archiveType: archiveType)) (<COUNT>/120)".localized().replacingOccurrences(of: "<COUNT>", with: "\(textCount)")
            
            if textCount < 120 {
                return true
            }
            return false
            
        case nicknameTextField:
            nicknameTitleLabel.text = "\(ProfilePageData.nickNameTitle(archiveType: archiveType)) (<COUNT>/120)".localized().replacingOccurrences(of: "<COUNT>", with: "\(textCount)")
            
            if textCount < 120 {
                return true
            }
            return false
            
        default:
            return true
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let textFieldText = textField.text, textField == birthDateTextField && textFieldText.isEmpty else { return }
        
        if let birthDate = viewModel?.birthInfoProfileItem?.birthDate {
            birthDateTextField.text = birthDate
        }
    }
}

// MARK: - PublicProfileLocationSetViewControllerDelegate
extension PublicProfilePersonalInfoViewController: PublicProfileLocationSetViewControllerDelegate {
    func locationSetViewControllerDidUpdate(_ locationVC: PublicProfileLocationSetViewController) {
        if let archiveType = viewModel?.archiveType {
            switch archiveType {
            case .person:
                if viewModel?.birthInfoProfileItem == nil {
                    viewModel?.createNewBirthProfileItem(newLocation: locationVC.pickedLocation)
                } else {
                    viewModel?.birthInfoProfileItem?.birthLocation = locationVC.pickedLocation
                }
                locationTextField.text = viewModel?.birthInfoProfileItem?.birthLocationFormated
                
            case .organization, .family, .nonProfit:
                if viewModel?.establishedInfoProfileItem == nil {
                    viewModel?.createNewEstablishedInfoProfileItem(newLocation: locationVC.pickedLocation)
                } else {
                    viewModel?.establishedInfoProfileItem?.establishedLocation = locationVC.pickedLocation
                }
                locationTextField.text = viewModel?.establishedInfoProfileItem?.establishedLocationFormated
            }
        }
        
        viewModel?.newLocnId = locationVC.pickedLocation?.locnID
        
        let locationDetails = getLocationDetails()
        mapView.isHidden = locationDetails == (0, 0)
        
        setLocation(locationDetails.latitude, locationDetails.longitude)
    }
}
