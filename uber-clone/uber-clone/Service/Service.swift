//
//  Service.swift
//  uber-clone
//
//  Created by marchelmon on 2021-05-12.
//

import Firebase
import FirebaseFirestore
import GeoFire //TODO: TA BORT

let DB_REF = Firestore.firestore()
let COLLECTION_USERS = DB_REF.collection("users")
let COLLECTION_DRIVER_LOCATIONS = DB_REF.collection("driver-locations")

struct Service {
    
    static let shared = Service()
    
    func fetchUserData(uid: String, completion: @escaping(User) -> Void) {
        COLLECTION_USERS.document(uid).getDocument { (snapshot, error) in
            if let error = error {
                print("DEBUG: fetch users: \(error.localizedDescription)")
                return
            }
            if let snapshot = snapshot {
                if let userData = snapshot.data() {
                    let user = User(uid: uid, data: userData)
                    completion(user)
                }
            }
        }
    }

    func fetchDrivers(userLocation: CLLocation, completion: @escaping(User) -> Void) {
        let currentLocation = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let kmRadius: Double = 1000
        let queryBounds = GFUtils.queryBounds(forLocation: currentLocation, withRadius: kmRadius)
        
        let queries = queryBounds.compactMap { (any) -> Query? in
            guard let bound = any as? GFGeoQueryBounds else { return nil }
            return COLLECTION_DRIVER_LOCATIONS.order(by: "geohash").start(at: [bound.startValue]).end(at: [bound.endValue])
        }
                
        for query in queries {
            query.getDocuments { (snapshot, error) in
                
                if let error = error {
                    print("ERROR: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else {
                    print("Unable to fetch snapshot data. \(String(describing: error))")
                    return
                }
                print(documents.count)
                for document in documents {
                    let lat = document.data()["lat"] as? Double ?? 0
                    let lng = document.data()["lng"] as? Double ?? 0
                    let coordinates = CLLocation(latitude: lat, longitude: lng)
                    
                    let distance = GFUtils.distance(from: userLocation, to: coordinates)
                    if distance <= kmRadius {
                        self.fetchUserData(uid: document.documentID) { user in
                            var driver = user
                            driver.location = coordinates
                            completion(driver)
                        }
                    }
                }
            }
        }
    }
}
