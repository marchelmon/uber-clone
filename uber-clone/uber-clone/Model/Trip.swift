//
//  Trip.swift
//  uber-clone
//
//  Created by marchelmon on 2021-05-26.
//

import Foundation
import CoreLocation



enum TripState: Int {
    case requested
    case denied
    case accepted
    case driverArrived
    case inProgress
    case arrivedAtDestination
    case completed
}


struct Trip {
    
    let pickupCoordinates: CLLocationCoordinate2D
    let destinationCoordinates: CLLocationCoordinate2D
    let passengerUid: String
    var driverUid: String?
    var state: TripState!
    
    init(passengerUid: String, dictionary: [String: Any]) {
        self.passengerUid = passengerUid
        self.driverUid = dictionary["driverUid"] as? String ?? ""

        if let pickupCoordinates = dictionary["pickupCoordinates"] as? NSArray {
            let lat = pickupCoordinates[0] as? CLLocationDegrees ?? CLLocationDegrees()
            let lng = pickupCoordinates[1] as? CLLocationDegrees ?? CLLocationDegrees()
            self.pickupCoordinates = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        } else {
            self.pickupCoordinates = CLLocationCoordinate2D()
        }
        if let destinationCoordinates = dictionary["destinationCoordinates"] as? NSArray {
            let lat = destinationCoordinates[0] as? CLLocationDegrees ?? CLLocationDegrees()
            let lng = destinationCoordinates[1] as? CLLocationDegrees ?? CLLocationDegrees()
            self.destinationCoordinates = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        } else {
            self.destinationCoordinates = CLLocationCoordinate2D()
        }
        
        if let state = dictionary["state"] as? Int {
            self.state = TripState(rawValue: state)
        }
        
    }
    
}
