//
//  PublicProfileLocationSetViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 13.01.2022.
//

import UIKit
import CoreLocation
import GoogleMaps
import GooglePlaces

protocol PublicProfileLocationSetViewControllerDelegate: AnyObject {
    func locationSetViewControllerDidUpdate(_ locationVC: PublicProfileLocationSetViewController)
}

class PublicProfileLocationSetViewController: BaseViewController<PublicProfilePageViewModel> {
    
    var file: FileViewModel!
    var locnVO: LocnVO? {
        if let archiveType = viewModel?.archiveType {
            switch archiveType {
            case .person:
                return viewModel?.birthInfoProfileItem?.locnVOs?.first
            case .family, .organization:
                return viewModel?.establishedInfoProfileItem?.locnVOs?.first
            }
        }
        return nil
    }
    
    weak var delegate: PublicProfileLocationSetViewControllerDelegate?
    
    @IBOutlet weak var searchBarContainer: UIView!
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    
    @IBOutlet weak var mapContainerView: UIView!
    var mapView: GMSMapView!
    var marker: GMSMarker!
    
    let placesClient = GMSPlacesClient()
    
    var pickedLocation: LocnVO? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleNavBar()
        initUI()
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
        
        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.standardAppearance.backgroundColor = .black
            navigationController?.navigationBar.scrollEdgeAppearance?.backgroundColor = .black
        } else {
            navigationController?.navigationBar.barTintColor = .black
        }
    }
    
    func initUI() {
        view.backgroundColor = .black
        
        let camera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 16.0)
        mapView = GMSMapView.map(withFrame: mapContainerView.bounds, camera: camera)
        mapView.delegate = self
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapContainerView.addSubview(mapView)
        
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        searchController!.searchBar.backgroundColor = UIColor.clear
        searchBarContainer.addSubview(searchController!.searchBar)

        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        definesPresentationContext = true
        
        if let latitude = locnVO?.latitude,
           let longitude = locnVO?.longitude {
            setLocation(latitude, longitude)
        } else {
            let coordinate = Constants.API.Locations.initialLocation
            setLocation(coordinate.latitude, coordinate.longitude)
            saveLocation(coordinate)
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed(_:)))
        navigationItem.title = "Set Location".localized()
    }
    
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func doneButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: {
            self.delegate?.locationSetViewControllerDidUpdate(self)
        })
    }
    
    func setLocation(_ latitude: Double, _ longitude: Double) {
        let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        
        mapView.moveCamera(GMSCameraUpdate.setTarget(coordinate, zoom: 6))
        
        if marker == nil {
            marker = GMSMarker()
        }
        marker.position = coordinate
        marker.map = mapView
    }

    func saveLocation(_ location: CLLocationCoordinate2D) {
        viewModel?.validateLocation(lat: location.latitude, long: location.longitude, completion: { status in
            if let locnVO = status {
                self.setLocation(location.latitude, location.longitude)
                self.pickedLocation = locnVO
            } else {
                self.view.showNotificationBanner(title: "There was a problem saving the location.".localized(), backgroundColor: .deepRed, textColor: .white)
            }
        })
    }
}

extension PublicProfileLocationSetViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        saveLocation(coordinate)
    }
}

extension PublicProfileLocationSetViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        
        saveLocation(place.coordinate)
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didFailAutocompleteWithError error: Error) {
        print("Error: ", error.localizedDescription)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
