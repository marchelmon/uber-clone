//
//  PickupController.swift
//  uber-clone
//
//  Created by marchelmon on 2021-05-26.
//

import UIKit
import MapKit

class PickupController: UIViewController {
    
    //MARK: - Properties
    
    private let mapView = MKMapView()
    
    let trip: Trip
    
    
    //MARK: - Lifecycle
    
    init(trip: Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    //MARK: - Actions
    
    //MARK: - API
    
    
}
