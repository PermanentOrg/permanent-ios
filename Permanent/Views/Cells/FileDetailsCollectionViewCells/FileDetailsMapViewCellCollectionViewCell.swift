//
//  FileDetailsMapViewCellCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.03.2021.
//

import UIKit
import MapKit

class FileDetailsMapViewCellCollectionViewCell: UICollectionViewCell {

    static let identifier = "FileDetailsMapViewCellCollectionViewCell"
    let regionInMeters: Double = 5000
    
    @IBOutlet weak var titleLabelField: UILabel!
    @IBOutlet weak var detailsTextField: UITextField!
    @IBOutlet weak var locationMapView: MKMapView!
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        detailsTextField.delegate = self
    }

    func configure(title: String, details: String, isDetailsFieldEditable: Bool = false) {
        titleLabelField.text = title
        titleLabelField.textColor = .white
        titleLabelField.font = Text.style9.font

        detailsTextField.text = details
        detailsTextField.backgroundColor = .clear
        detailsTextField.textColor = .white
        detailsTextField.font = Text.style8.font
        detailsTextField.isUserInteractionEnabled = isDetailsFieldEditable
        if isDetailsFieldEditable {
            detailsTextField.backgroundColor = .darkGray
        }
    }
    
    func setLocation(_ latitude: Double, _ longitude: Double) {
        let currentLocation = MKPointAnnotation()
        currentLocation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        locationMapView.addAnnotation(currentLocation)
        let region = MKCoordinateRegion(center: currentLocation.coordinate, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        locationMapView.setRegion(region, animated: false)
        locationMapView.showsPointsOfInterest = true
        locationMapView.isUserInteractionEnabled = false
    }
}

extension FileDetailsMapViewCellCollectionViewCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
