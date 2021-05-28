//
//  Service.swift
//  uber-clone
//
//  Created by marchelmon on 2021-05-12.
//

import Firebase
import FirebaseFirestore
import GeoFire

let DB_REF = Firestore.firestore()
let COLLECTION_USERS = DB_REF.collection("users")
let COLLECTION_DRIVER_LOCATIONS = DB_REF.collection("driver-locations")
let COLLECTION_TRIPS = DB_REF.collection("trips")

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
        let meterRadius: Double = 20 * 1000 //10 mil
        let queryBounds = GFUtils.queryBounds(forLocation: currentLocation, withRadius: meterRadius)
        
        let queries = queryBounds.compactMap { (any) -> Query? in
            guard let bound = any as? GFGeoQueryBounds else { return nil }
            return COLLECTION_DRIVER_LOCATIONS.order(by: "geohash").start(at: [bound.startValue]).end(at: [bound.endValue])
        }
        
        for query in queries {
            query.addSnapshotListener { (snapshot, error) in
                
                if let error = error {
                    print("ERROR: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else {
                    print("Unable to fetch snapshot data. \(String(describing: error))")
                    return
                }
                for document in documents {
                    let lat = document.data()["lat"] as? Double ?? 0
                    let lng = document.data()["lng"] as? Double ?? 0
                    let coordinates = CLLocation(latitude: lat, longitude: lng)
                    
                    
                    let distance = GFUtils.distance(from: userLocation, to: coordinates)
                    if distance <= meterRadius {
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
    
    func uploadTrip(_ pickUpCoordinates: CLLocationCoordinate2D, destinationCoordinates: CLLocationCoordinate2D, completion: @escaping(Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let pickUpArray = [pickUpCoordinates.latitude, pickUpCoordinates.longitude]
        let destinationArray = [destinationCoordinates.latitude, destinationCoordinates.longitude]
        
        let values = [
            "pickupCoordinates": pickUpArray,
            "destinationCoordinates": destinationArray,
            "state": TripState.requested.rawValue
        ] as [String: Any]
        
        COLLECTION_TRIPS.document(uid).setData(values, completion: completion)
    }
    
    func observeTrips(completion: @escaping(Trip) -> Void) {
        COLLECTION_TRIPS.addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error observe trips: \(error.localizedDescription)")
            }
            guard let documents = snapshot?.documents else { print("No documents"); return }
            for document in documents {
                let data = document.data()
                let trip = Trip(passengerUid: document.documentID, dictionary: data)
                completion(trip)
            }
        }
    }
    
    func acceptTrip(trip: Trip, completion: @escaping(Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let values = ["driverUid": uid, "state": TripState.accepted.rawValue] as [String: Any]
        
        COLLECTION_TRIPS.document(trip.passengerUid).updateData(values, completion: completion)
    }
    
    func observeCurrentTrip(completion: @escaping(Trip) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        COLLECTION_TRIPS.document(uid).addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error observe trips: \(error.localizedDescription)")
            }
            guard let data = snapshot?.data() else { return }
            let trip = Trip(passengerUid: uid, dictionary: data)
            completion(trip)
        }
    }
    
}
