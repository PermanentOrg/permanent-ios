//
//  LocationSetViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.03.2021.
//

import UIKit
import MapKit
import AutoCompletion
import CoreLocation

protocol LocationSetViewControllerDelegate: class {
    func locationSetViewControllerDidUpdate(_ locationVC: LocationSetViewController)
}

class LocationSetViewController: BaseViewController<FilePreviewViewModel> {
    
    var file: FileViewModel!
    var recordVO: RecordVOData? {
        return viewModel?.recordVO?.recordVO
    }
    //var currentLocation = MKPointAnnotation()
    var searchedLocations: [String: (CLLocationCoordinate2D, Double)] = ["none": (CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0) ,0.0)]
    
    weak var delegate: LocationSetViewControllerDelegate?
    
    let address = "1 Infinite Loop, CA, USA"
    let geocoder = CLGeocoder()

    @IBOutlet weak var searchBar: AutoCompletionTextField!
    @IBOutlet weak var locationSetMapView: MKMapView!
    
    var pickedLocation: LocnVO? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleNavBar()
        initUI()
        
        locationSetMapView.delegate = self
        
        searchBar.suggestionsResultDataSource = self
        searchBar.suggestionsResultDelegate = self
        searchBar.delegate = self
        
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
        
        searchBar.backgroundColor = .white
        searchBar.textColor = .black
        
        searchBar.tableCornerRadius = 5
        searchBar.tableBorderColor = .white
        searchBar.selectedBorderColor = .white
        searchBar.placeholder = "Search address"
        searchBar.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: searchBar.frame.height))
       // searchBar.leftViewMode = .always

        if let latitude = recordVO?.locnVO?.latitude,
           let longitude = recordVO?.locnVO?.longitude {
            setMapRegion(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            setMapAnnotation(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
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
            let coordinates: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: touchLocation.latitude, longitude: touchLocation.longitude)
            saveLocation(coordinates)
        }
    }
    
    func setMapRegion(_ coordinates: CLLocationCoordinate2D,_ radiusMeters: Double = 2000) {
        let currentLocation = MKPointAnnotation()
        currentLocation.coordinate = coordinates
        let radius = (radiusMeters < 2000) ? ( 2000 ) : ( radiusMeters )
        
        let region = MKCoordinateRegion(center: currentLocation.coordinate, latitudinalMeters: radius, longitudinalMeters: radius)
        
        locationSetMapView.setRegion(region, animated: true)
        locationSetMapView.showsPointsOfInterest = true
        locationSetMapView.isUserInteractionEnabled = true
    }
    
    func setMapAnnotation(_ coordinates: CLLocationCoordinate2D) {
        let currentLocation = MKPointAnnotation()
        currentLocation.coordinate = coordinates
        locationSetMapView.removeAnnotations(locationSetMapView.annotations)
        locationSetMapView.addAnnotation(currentLocation)
    }
    
    func saveLocation(_ location: CLLocationCoordinate2D) {
        viewModel?.validateLocation(lat: location.latitude, long: location.longitude, completion: { status in
            if let locnVO = status {
                self.setMapAnnotation(location)
                
                self.pickedLocation = locnVO
            } else {
                self.view.showNotificationBanner(title: .errorMessage, backgroundColor: .deepRed, textColor: .white)
            }
        })
    }
}
extension LocationSetViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
    }
}
extension LocationSetViewController: AutoCompletionTextFieldDataSource {
    func fetchSuggestions(forIncompleteString incompleteString: String!, withCompletionBlock completion: FetchCompletionBlock!) {
        if incompleteString.count > 2 {
            geocoder.geocodeAddressString(incompleteString,
                                          completionHandler: { (result, error) in
                                            if let placemarks = result {
                                                let placemarksDictionary = placemarks.map { placemark -> [String:String] in
                                                    let addressElements: [String?] = [placemark.thoroughfare, placemark.subThoroughfare, placemark.locality, placemark.administrativeArea, placemark.country]
                                                    let addressString = addressElements.compactMap { $0 }.joined(separator: ", ")
                                                    
                                                    if let coordinate = placemark.location?.coordinate,
                                                       let radius = placemark.region as? CLCircularRegion {
                                                        self.searchedLocations[addressString] = (coordinate,radius.radius)
                                                    }
                                                    return ["title": addressString]
                                                }
                                                completion(placemarksDictionary, "title")
                                            }
                                          })
        }
    }
}

extension LocationSetViewController: AutoCompletionTextFieldDelegate {
    func textField(_ textField: AutoCompletionTextField!, didSelectItem selectedItem: Any!) {
        if let item = selectedItem as? [String: String] {
            let itemTitle: String = item["title"] ?? ""
            searchBar.text = itemTitle
            if let location: CLLocationCoordinate2D = self.searchedLocations[itemTitle]?.0,
               let radius: Double = self.searchedLocations[itemTitle]?.1 {
                setMapRegion(location,radius)
                saveLocation(location)
            }
            self.view.endEditing(true)
        }
    }
}

extension LocationSetViewController: AutoCompletionAnimator {
    func showSuggestions(for textField: AutoCompletionTextField!, table: UITableView!, numberOfItems count: Int) {
        print("show tableview")
    }
    
    func hideSuggestions(for textField: AutoCompletionTextField!, table: UITableView!) {
        print("hide tableview")
    }
    
}

extension LocationSetViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}
