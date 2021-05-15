//
//  DriverAnnotation.swift
//  uber-clone
//
//  Created by marchelmon on 2021-05-15.
//

import MapKit

class DriverAnnotation: NSObject, MKAnnotation {
    
    var uid: String
    var coordinate: CLLocationCoordinate2D
    
    
    init(uid: String, coordinate: CLLocationCoordinate2D) {
        self.uid = uid
        self.coordinate = coordinate
    }
    
}
