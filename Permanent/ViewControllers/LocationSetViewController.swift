//
//  LocationSetViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.03.2021.
//

import UIKit
import MapKit

class LocationSetViewController: UIViewController {
    
    @IBOutlet weak var locationSetMapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.endEditing(true)
    }
    
    func initUI() {
        view.backgroundColor = .black
        
        searchBar.setDefaultStyle(placeholder: "Search location")
        searchBar.backgroundColor = .clear
    }
    
}
