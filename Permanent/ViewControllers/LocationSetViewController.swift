//
//  LocationSetViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.03.2021.
//

import UIKit
import MapKit

protocol LocationSetViewControllerDelegate: class {
    func locationSetViewControllerDidUpdate(_ locationVC: LocationSetViewController)
}

class LocationSetViewController: BaseViewController<FilePreviewViewModel> {
    
    var file: FileViewModel!
    var recordVO: RecordVOData? {
        return viewModel?.recordVO?.recordVO
    }
    var currentLocation = MKPointAnnotation()
    
    weak var delegate: LocationSetViewControllerDelegate?
    
    @IBOutlet weak var locationSetMapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var pickedLocation: LocnVO? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleNavBar()
        initUI()
        
        locationSetMapView.delegate = self
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        locationSetMapView.addGestureRecognizer(longPressRecognizer)
        longPressRecognizer.minimumPressDuration = 0.8
   }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    override func styleNavBar() {
        super.styleNavBar()
        
        navigationController?.navigationBar.barTintColor = .black
    }
    
    func initUI() {
        view.backgroundColor = .black
        
        searchBar.setDefaultStyle(placeholder: "Search location")
        searchBar.backgroundColor = .darkGray

        if let latitude = recordVO?.locnVO?.latitude,
           let longitude = recordVO?.locnVO?.longitude {
            setLocation(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed(_:)))
    }
    
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func doneButtonPressed(_ sender: UIBarButtonItem) {
        showSpinner()
        viewModel?.update(file: file, name: nil, description: nil, date: nil, location: pickedLocation, completion: { (success) in
            self.hideSpinner()
            if success {
                self.delegate?.locationSetViewControllerDidUpdate(self)
                self.dismiss(animated: true, completion: nil)
            } else {
                self.showErrorAlert(message: .errorMessage)
            }
        })
    }
    
    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == .began  {
            let touchPoint = sender.location(in: self.locationSetMapView)
            let touchLocation = locationSetMapView.convert(touchPoint, toCoordinateFrom: locationSetMapView)
            
            viewModel?.validateLocation(lat: Double(touchLocation.latitude), long: Double(touchLocation.longitude), completion: { status in
                if let locnVO = status {
                    self.setMapAnnotation(touchLocation)
                    
                    self.pickedLocation = locnVO
                } else {
                    self.view.showNotificationBanner(title: .errorMessage, backgroundColor: .deepRed, textColor: .white)
                }
            })
        }
    }
    
    func setLocation(_ coordinates: CLLocationCoordinate2D) {
        currentLocation.coordinate = coordinates
        locationSetMapView.addAnnotation(currentLocation)
        let region = MKCoordinateRegion(center: currentLocation.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        locationSetMapView.setRegion(region, animated: true)
        locationSetMapView.showsPointsOfInterest = true
        locationSetMapView.isUserInteractionEnabled = true
    }
    
    func setMapAnnotation(_ coordinates: CLLocationCoordinate2D) {
        currentLocation.coordinate = coordinates
        locationSetMapView.addAnnotation(currentLocation)
    }
}
extension LocationSetViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
    }
}
