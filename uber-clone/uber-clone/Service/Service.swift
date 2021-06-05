//
//  Service.swift
//  uber-clone
//
//  Created by marchelmon on 2021-05-12.
//

import Firebase
import FirebaseFirestore
import GeoFire


//MARK: - Firestore Collections

let DB_REF = Firestore.firestore()
let COLLECTION_USERS = DB_REF.collection("users")
let COLLECTION_DRIVER_LOCATIONS = DB_REF.collection("driver-locations")
let COLLECTION_TRIPS = DB_REF.collection("trips")


struct DriverService {
    static let shared = DriverService()
    
    func observeTrips(completion: @escaping(Trip, Bool) -> Void) {
        
        COLLECTION_TRIPS.addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error observe trips: \(error.localizedDescription)")
                return
            }
            
            var tripRemoved: Bool = false
            guard let documents = snapshot?.documents else { return }
            guard let changedDocument = snapshot?.documentChanges.first?.document else { return }
            let changedTrip = Trip(passengerUid: changedDocument.documentID, dictionary: changedDocument.data())
              
            if Service.totalTripCount > documents.count {
                tripRemoved = true
                if changedTrip.driverUid == Auth.auth().currentUser?.uid {
                    completion(changedTrip, tripRemoved)
                }
            } else if Service.totalTripCount < documents.count {
                completion(changedTrip, tripRemoved)
            }
            Service.totalTripCount = documents.count
        }
    }
    
    func acceptTrip(trip: Trip, completion: @escaping(Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let values = ["driverUid": uid, "state": TripState.accepted.rawValue] as [String: Any]
        
        COLLECTION_TRIPS.document(trip.passengerUid).updateData(values, completion: completion)
    }
    
    func updateDriverLocation(location: CLLocation) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        
        let hash = GFUtils.geoHash(forLocation: CLLocationCoordinate2D(latitude: lat, longitude: lng))
                        
        let locationData: [String: Any] = [
            "geohash": hash,
            "lat": lat,
            "lng": lng
        ]
        COLLECTION_DRIVER_LOCATIONS.document(uid).updateData(locationData)
    }
}

struct PassengerService {
    static let shared = PassengerService()
    
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
                guard let documents = snapshot?.documents else { return }
                for document in documents {
                    let lat = document.data()["lat"] as? Double ?? 0
                    let lng = document.data()["lng"] as? Double ?? 0
                    let coordinates = CLLocation(latitude: lat, longitude: lng)
                    
                    
                    let distance = GFUtils.distance(from: userLocation, to: coordinates)
                    if distance <= meterRadius {
                        Service.shared.fetchUserData(uid: document.documentID) { user in
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
    
    func deleteTrip(completion: @escaping(Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        COLLECTION_TRIPS.document(uid).delete(completion: completion)
    }
    
    func saveFavoriteLocation(locationString: String, locationType: LocationType, completion: ((Error?) -> Void)?) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let key: String = locationType == .home ? "home" : "work"
        
        COLLECTION_USERS.document(uid).updateData([key: locationString], completion: completion)
    }
    
}

struct Service {
    
    static let shared = Service()
    
    static var totalTripCount: Int = 0
    
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
    
    func getFirebaseTripCount(completion: @escaping(Int) -> Void) {
        COLLECTION_TRIPS.getDocuments { (snapshot, error) in
            if let error = error {
                print("ERROR fetching all trips: \(error.localizedDescription)")
                completion(0)
                return
            }
            completion(snapshot?.documents.count ?? 0)
        }
    }
    
    func updateTripState(trip: Trip, state: TripState, completion: @escaping(Error?) -> Void) {
        COLLECTION_TRIPS.document(trip.passengerUid).updateData(["state": state.rawValue], completion: completion)
    }
    
}
