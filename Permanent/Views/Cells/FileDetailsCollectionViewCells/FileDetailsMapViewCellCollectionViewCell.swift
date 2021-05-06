//
//  FileDetailsMapViewCellCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.03.2021.
//

import UIKit
import MapKit

class FileDetailsMapViewCellCollectionViewCell: FileDetailsBaseCollectionViewCell {

    static let identifier = "FileDetailsMapViewCellCollectionViewCell"
    
    let regionInMeters: Double = 1500
 
    @IBOutlet weak var titleLabelField: UILabel!
    @IBOutlet weak var detailsLabelField: UILabel!
    @IBOutlet weak var locationMapView: MKMapView!
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        locationMapView.removeAnnotations(locationMapView.annotations)
    }

    override func configure(withViewModel viewModel: FilePreviewViewModel, type: FileDetailsViewController.CellType) {
        super.configure(withViewModel: viewModel, type: type)

        titleLabelField.text = title
        titleLabelField.textColor = .white
        titleLabelField.font = Text.style9.font

        if let locnVO = viewModel.recordVO?.recordVO?.locnVO {
            let address = viewModel.getAddressString([locnVO.streetNumber, locnVO.streetName, locnVO.locality, locnVO.country])
            detailsLabelField.text = address
        } else {
            detailsLabelField.text = isEditable ? "Tap to set location".localized() : "No Location".localized()
        }
        
        detailsLabelField.backgroundColor = .clear
        detailsLabelField.textColor = .white
        detailsLabelField.font = Text.style8.font
        detailsLabelField.layer.cornerRadius = 5
        detailsLabelField.layer.masksToBounds = true
        detailsLabelField.baselineAdjustment = .alignCenters
        
        let locationDetails = getLocationDetails()
        locationMapView.isHidden = locationDetails == (0,0)
        
        setLocation(locationDetails.latitude, locationDetails.longitude)
        
        if isEditable {
            detailsLabelField.backgroundColor = .darkGray
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
    
    func getLocationDetails() -> (latitude: Double, longitude: Double) {
        if let latitude = viewModel?.recordVO?.recordVO?.locnVO?.latitude,
           let longitude = viewModel?.recordVO?.recordVO?.locnVO?.longitude {
            return (latitude,longitude)
        } else {
            return (0,0)
        }
    }
}
