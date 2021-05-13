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
let DRIVER_LOCATIONS = DB_REF.collection("driver-locations")

struct Service {
    
    static let shared = Service()
    
    func fetchUserData(completion: @escaping(User) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        COLLECTION_USERS.document(uid).getDocument { (snapshot, error) in
            if let error = error {
                print("DEBUG: fetch users: \(error.localizedDescription)")
                return
            }
            if let snapshot = snapshot {
                if let userData = snapshot.data() {
                    let user = User(data: userData)
                    completion(user)
                }
            }
        }
    }

    
    func bajs() {
        let latitude = 51.5074
        let longitude = 0.12780
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        let hash = GFUtils.geoHash(forLocation: location)

        let documentData: [String: Any] = [
            "geohash": hash,
            "lat": latitude,
            "lng": longitude
        ]

        let driverLocationRef = DRIVER_LOCATIONS.document("")
        driverLocationRef.updateData(documentData) { error in
            if let error = error {
                print("Error updating user location: \(error.localizedDescription)")
                return
            }
            
        }
        let geofire = GeoFire()

        let loc = CLLocation(latitude: latitude, longitude: longitude)
        geofire.setLocation(loc, forKey: "") { error in
            if let error = error {
                print("ERROR: \(error.localizedDescription)")
                return
            }
        }
        
    }
    
    
}
