//
//  FileDetailsMapViewCellCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.03.2021.
//

import UIKit
import CoreLocation
import GoogleMaps

class FileDetailsMapViewCellCollectionViewCell: FileDetailsBaseCollectionViewCell {

    static let identifier = "FileDetailsMapViewCellCollectionViewCell"
 
    @IBOutlet weak var titleLabelField: UILabel!
    @IBOutlet weak var detailsLabelField: UILabel!
    @IBOutlet weak var mapViewContainer: UIView!
    
    var mapView: GMSMapView!
    var marker: GMSMarker!
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let camera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 9.9)
        mapView = GMSMapView.map(withFrame: mapViewContainer.bounds, camera: camera)
        mapView.isUserInteractionEnabled = false
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapViewContainer.addSubview(mapView)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
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
        mapViewContainer.isHidden = locationDetails == (0,0)
        
        setLocation(locationDetails.latitude, locationDetails.longitude)
        
        if isEditable {
            detailsLabelField.backgroundColor = .darkGray
        }
    }
    
    func setLocation(_ latitude: Double, _ longitude: Double) {
        let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        
        mapView.moveCamera(GMSCameraUpdate.setTarget(coordinate, zoom: 9.9))

        if marker == nil {
            marker = GMSMarker()
        }
        marker.position = coordinate
        marker.map = mapView
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
