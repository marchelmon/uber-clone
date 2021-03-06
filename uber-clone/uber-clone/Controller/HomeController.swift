//
//  HomeController.swift
//  uber-clone
//
//  Created by marchelmon on 2021-05-09.
//

import UIKit
import Firebase
import MapKit

private let reuseIdentifier = "LocationCell"
private let annotationIdentifier = "DriverAnnotation"

private enum ActionButtonConfig {
    case showMenu
    case dismissActionView
    
    init() {
        self = .showMenu
    }
}

private enum AnnotationType: String {
    case pickup
    case destination
}

protocol HomeControllerDelegate: class {
    func handleMenuToggle()
}

class HomeController: UIViewController {
    
    //MARK: - Properties
    
    private let mapView = MKMapView()
    private let locationManager: CLLocationManager = LocationHandler.shared.locationManager
    private var route: MKRoute?
    
    private let inputActivationView = LocationInputActivationView()
    private let rideActionView = RideActionView()
    private let locationInputView = LocationInputView()
    private let tableView = UITableView()
    
    private var searchResults = [MKPlacemark]()
    private var favoriteLocations = [MKPlacemark]()
    
    private final let locationInputViewHeight: CGFloat = 200
    private final let rideActionViewHeight: CGFloat = 300
    
    private var actionButtonConfig = ActionButtonConfig()
    
    weak var delegate: HomeControllerDelegate?
    
    var user: User? {
        didSet {
            locationInputView.user = user
            if user?.accountType == .passenger {
                fetchDrivers()
                configureInputActivationView()
                observeCurrentTrip()
                configureFavoriteLocations()
            } else {
                observeTrips()
            }
        }
    }
    
    private var trip: Trip? {
        didSet {
            guard let user = user else { return }
            if user.accountType == .driver {
                guard let trip = trip else { return }
                let controller = PickupController(trip: trip)
                controller.delegate = self
                controller.modalPresentationStyle = .fullScreen
                present(controller, animated: true, completion: nil)
            } else {
                print("DEBUG: SHow ride action view for accepted trip")
            }
        }
    }
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        return button
    }()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        
        inputActivationView.delegate = self
        locationInputView.delegate = self
        rideActionView.delegate = self
        locationManager.delegate = self
        
        enableLocationServices()
    }
    
    //MARK: - Actions
    
    @objc func actionButtonPressed() {
        switch actionButtonConfig {
        case .showMenu:
            delegate?.handleMenuToggle()
        case .dismissActionView:
            
            removeAnnotationsAndOverlays()
            
            UIView.animate(withDuration: 0.3) {
                self.inputActivationView.alpha = 1
                self.configureActionButton(config: .showMenu)
            }
            
            mapView.showAnnotations(mapView.annotations, animated: true)
            animateRideActionView(shouldShow: false)
        }
    }
    
    //MARK: - Passenger API
    
    func startTrip() {
        guard let trip = self.trip else { return }
        Service.shared.updateTripState(trip: trip, state: .inProgress) { error in
            self.rideActionView.config = .tripInProgress
            self.removeAnnotationsAndOverlays()

            self.mapView.addAnnotationAndSelect(forCoordinate: trip.destinationCoordinates)

            let placemark = MKPlacemark(coordinate: trip.destinationCoordinates)
            let mapItem = MKMapItem(placemark: placemark)
            self.generatePolyline(toDestionation: mapItem)
            
            self.setCustomRegion(withType: .destination, withCoordinates: trip.destinationCoordinates)
            self.mapView.zoomToFit(annotations: self.mapView.annotations)
        }
    }
    
    func observeCurrentTrip() {
        PassengerService.shared.observeCurrentTrip { trip in
            self.trip = trip
            guard let driverUid = trip.driverUid else { return }
                        
            switch trip.state as TripState {
            case .requested:
                print("Requested ")
            case .denied:
                print("DenIED DIIDIDDIIDIDI")
                self.shouldPresentLoadingView(false)
                self.presentAlertController(withTitle: "Ops", withMessage: "It looks like we couldn't find you a driver, please try again...")
                PassengerService.shared.deleteTrip { error in
                    self.centerMapOnUserLocation()
                    self.configureActionButton(config: .showMenu)
                    self.inputActivationView.alpha = 1
                    self.removeAnnotationsAndOverlays()
                }
            case .accepted:
                self.shouldPresentLoadingView(false)
                self.removeAnnotationsAndOverlays()
                self.zoomForActiveTrip(withDriverUid: driverUid)
                
                Service.shared.fetchUserData(uid: driverUid) { driver in
                    self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: driver)
                }
            case .driverArrived:
                self.rideActionView.config = .driverArrived
            case .inProgress:
                self.rideActionView.config = .tripInProgress
            case .arrivedAtDestination:
                self.rideActionView.config = .endTrip
            case .completed:
                PassengerService.shared.deleteTrip { error in
                    self.animateRideActionView(shouldShow: false)
                    self.centerMapOnUserLocation()
                    self.configureActionButton(config: .showMenu)
                    self.presentAlertController(withTitle: "Trip completed", withMessage: "Hope you enjoyed your trip")
                    self.inputActivationView.alpha = 1
                    
                }
            }
        }
    }
    
    func fetchDrivers() {
        guard let location = locationManager.location else { return }
        PassengerService.shared.fetchDrivers(userLocation: location) { driver in
            guard let coordinate = driver.location?.coordinate else { return }
            let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)

            var driverIsVisable: Bool {
                return self.mapView.annotations.contains { annotation -> Bool in
                    guard let driverAnnotation = annotation as? DriverAnnotation else { return false }
                    if driverAnnotation.uid == driver.uid {
                        driverAnnotation.updateAnnotationPosition(withCoordinate: coordinate)
                        self.zoomForActiveTrip(withDriverUid: driver.uid)
                        return true
                    }
                    return false
                }
            }
            if !driverIsVisable {
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    //MARK: - Driver API
    
    func observeTrips() {
        DriverService.shared.observeTrips { (trip, removed) in
            if removed {
                self.removeAnnotationsAndOverlays()
                self.animateRideActionView(shouldShow: false)
                self.centerMapOnUserLocation()
                if trip.state != .completed {
                    self.presentAlertController(withTitle: "Oops!", withMessage: "The passenger has canceled this trip")
                }
                return
            }
            self.trip = trip
        }
    }
        
    
    //MARK: - Helpers
    
    func configureFavoriteLocations() {
        guard let user = user else { return }
        favoriteLocations.removeAll()
        
        if let home = user.home {
            geocodeAddressString(address: home)
        }
        if let work = user.work {
            geocodeAddressString(address: work)
        }
    }
    
    func geocodeAddressString(address: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            guard let clPlacemark = placemarks?.first else { return }
            let placemark = MKPlacemark(placemark: clPlacemark)
            self.favoriteLocations.append(placemark)
            self.tableView.reloadData()
        }
    }
    
    func presentLoginController() {
        DispatchQueue.main.async {
            let controller = UINavigationController(rootViewController: LoginController())
            controller.modalPresentationStyle = .fullScreen
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    func configureUI() {
        configureMapView()
        configureTableView()
        configureRideActionView()
        
        view.addSubview(actionButton)
        actionButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingTop: 16, paddingLeft: 20, width: 30, height: 30)
    }
    
    func configureInputActivationView() {
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDimensions(width: view.frame.width - 64, height: 50)
        inputActivationView.anchor(top: actionButton.bottomAnchor, paddingTop: 20)
        inputActivationView.alpha = 0
        
        UIView.animate(withDuration: 2) {
            self.inputActivationView.alpha = 1
        }
    }
    
    func configureMapView() {
        view.addSubview(mapView)
        mapView.frame = view.frame
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
        
        guard let coordinate = locationManager.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: CLLocationDistance(exactly: 5000)!, longitudinalMeters: CLLocationDistance(exactly: 5000)!)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
    
    func configureLocationInputView() {
        view.addSubview(locationInputView)
        locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: locationInputViewHeight)
        locationInputView.alpha = 0

        UIView.animate(withDuration: 0.3) {
            self.tableView.frame.origin.y = self.locationInputViewHeight
        }
        UIView.animate(withDuration: 0.5) {
            self.locationInputView.alpha = 1
        }
    }
    
    func configureRideActionView() {
        view.addSubview(rideActionView)
        rideActionView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: rideActionViewHeight)
    }
    
    func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(LocationCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 60
        tableView.tableFooterView = UIView()
        tableView.addShadow()
        
        tableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: view.frame.height - locationInputViewHeight)
                
        view.addSubview(tableView)

    }
    
    fileprivate func configureActionButton(config: ActionButtonConfig) {
        switch config {
        case .showMenu:
            self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .showMenu
        case .dismissActionView:
            actionButton.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp-1").withRenderingMode(.alwaysOriginal), for: .normal)
            actionButtonConfig = .dismissActionView
        }
    }
    
    func dismissLocationView(completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
            self.locationInputView.removeFromSuperview()

        }, completion: completion)
    }
    
    func animateRideActionView(shouldShow: Bool, destination: MKPlacemark? = nil, config: RideActionViewConfiguration? = nil, user: User? = nil) {
        let yOrigin = self.view.frame.height - (shouldShow ? self.rideActionViewHeight : 0)
        
        UIView.animate(withDuration: 0.3) {
            self.rideActionView.frame.origin.y = yOrigin
        }
        
        if shouldShow {
            guard let config = config else { return }
            
            if let destination = destination {
                self.rideActionView.destination = destination
            }
            if let user = user {
                rideActionView.user = user
            }
            rideActionView.config = config
        }
    }
    
}

//MARK: - Map helper functions

private extension HomeController {
    func searchBy(naturalLanguageQuery: String, completion: @escaping([MKPlacemark]) -> Void) {
        var results = [MKPlacemark]()
        
        let request = MKLocalSearch.Request()
        request.region = mapView.region
        request.naturalLanguageQuery = naturalLanguageQuery
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            guard let response = response else { return }
            
            response.mapItems.forEach { item in
                results.append(item.placemark)
            }
            completion(results)
        }
    }
    func generatePolyline(toDestionation destination: MKMapItem) {
        
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.transportType = .automobile
        
        let directionRequest = MKDirections(request: request)
        directionRequest.calculate { (response, error) in
            guard let response = response else { return }
            self.route = response.routes[0]
            guard let polyline = self.route?.polyline else { return }
            self.mapView.addOverlay(polyline)
            
        }
    }
    
    func removeAnnotationsAndOverlays() {
        mapView.annotations.forEach { annotation in
            if let anno = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(anno)
            }
        }
        if mapView.overlays.count > 0 {
            mapView.removeOverlay(mapView.overlays[0])
        }
    }
    
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
    }
    
    func setCustomRegion(withType type: AnnotationType, withCoordinates coordinates: CLLocationCoordinate2D) {
        let region = CLCircularRegion(center: coordinates, radius: 80, identifier: type.rawValue)
        locationManager.startMonitoring(for: region)
    }
    
    func zoomForActiveTrip(withDriverUid uid: String) {
        var annotations = [MKAnnotation]()
        
        self.mapView.annotations.forEach { annotation in
            if let anno = annotation as? DriverAnnotation {
                if anno.uid == uid {
                    annotations.append(anno)
                }
            }
            
            if let userAnno = annotation as? MKUserLocation {
                annotations.append(userAnno)
            }
        }
        self.mapView.zoomToFit(annotations: annotations)
    }
    
}

//MARK: - MKMapViewDelegate

extension HomeController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let userLocation = userLocation.location else { return }
        guard let user = self.user else { return }
        guard user.accountType == .driver else { return
            
        }
        DriverService.shared.updateDriverLocation(location: userLocation)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            view.image = #imageLiteral(resourceName: "chevron-sign-to-right")
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let route = self.route {
            let polyline = route.polyline
            let lineRenderer = MKPolylineRenderer(polyline: polyline)
            lineRenderer.strokeColor = .mainBlueTint
            lineRenderer.lineWidth = 4
            return lineRenderer
        }
        return MKOverlayRenderer()
    }
    
}

//MARK: - CLLocationManagerDelegate

extension HomeController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        if region.identifier == AnnotationType.pickup.rawValue {
            print("Did start monitoring PICKUP region: \(region)")
        } else if region.identifier == AnnotationType.destination.rawValue {
            print("Did start monitoring DESTINATION region: \(region)")

        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let trip = self.trip else { return }
        
        if region.identifier == AnnotationType.pickup.rawValue {
            print("Did enter PICKUP region: \(region)")
            Service.shared.updateTripState(trip: trip, state: .driverArrived) { error in
                self.rideActionView.config = .pickupPassenger
            }
        } else if region.identifier == AnnotationType.destination.rawValue {
            print("Did enter DESTINATION region: \(region)")
            Service.shared.updateTripState(trip: trip, state: .arrivedAtDestination) { error in
                self.rideActionView.config = .endTrip
            }
        }
    }
    
    func enableLocationServices() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("Restricted")
        case .authorizedAlways:
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        @unknown default:
            print("DEFAULT")
        }
    }
}

extension HomeController: LocationInputActivationViewDelegate {
    func presentLocationInputView() {
        inputActivationView.alpha = 0
        configureLocationInputView()
    }
}

extension HomeController: LocationInputViewDelegate {
    func dismissLocationInputView() {
        dismissLocationView { _ in
            UIView.animate(withDuration: 0.5) {
                self.inputActivationView.alpha = 1
            }
        }
    }
    func executeSearch(query: String) {
        searchBy(naturalLanguageQuery: query) { results in
            self.searchResults = results
            self.tableView.reloadData()
        }
    }
    
}

//MARK: - TableViewDelegate, TableViewDataSource

extension HomeController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Favorite Locations" : "Results"
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? favoriteLocations.count : searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! LocationCell
        
        if indexPath.section == 0 {
            cell.placemark = favoriteLocations[indexPath.row]
            
        }
        
        if indexPath.section == 1 {
            cell.placemark = searchResults[indexPath.row]
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedPlacemark = indexPath.section == 0 ? favoriteLocations[indexPath.row]: searchResults[indexPath.row]
        
        configureActionButton(config: .dismissActionView)
        
        let destination = MKMapItem(placemark: selectedPlacemark)
        generatePolyline(toDestionation: destination)
        
        dismissLocationView { _ in
            self.mapView.addAnnotationAndSelect(forCoordinate: selectedPlacemark.coordinate)
            let annotations = self.mapView.annotations.filter({ !$0.isKind(of: DriverAnnotation.self) })
            self.mapView.zoomToFit(annotations: annotations)
            self.animateRideActionView(shouldShow: true, destination: selectedPlacemark, config: .requestRide)
            
        }
    }
}

//MARK: - RideActionViewDelegate

extension HomeController: RideActionViewDelegate {
    func uploadTrip(_ view: RideActionView) {
        guard let pickupCoordinates = locationManager.location?.coordinate else { return }
        guard let destinationCoordinates = view.destination?.coordinate else { return }
        
        shouldPresentLoadingView(true, message: "Looking for your ride...")
        
        PassengerService.shared.uploadTrip(pickupCoordinates, destinationCoordinates: destinationCoordinates) { error in
            if let error = error {
                print("No trip uploaded error: \(error.localizedDescription)")
                return
            }
            UIView.animate(withDuration: 0.3) {
                self.rideActionView.frame.origin.y = self.view.frame.height
            }
        }
    }
    func cancelTrip() {
        PassengerService.shared.deleteTrip { error in
            if let error = error {
                print("Deleting trip failed: \(error.localizedDescription)")
                return
            }
            self.animateRideActionView(shouldShow: false)
            self.removeAnnotationsAndOverlays()
            self.centerMapOnUserLocation()
            self.inputActivationView.alpha = 1
            self.configureActionButton(config: .showMenu)
        }
    }
    func pickupPassenger() {
        startTrip()
    }
    func dropOffPassenger() {
        guard let trip = trip else { return }
        Service.shared.updateTripState(trip: trip, state: .completed) { error in
            self.removeAnnotationsAndOverlays()
            self.centerMapOnUserLocation()
            self.animateRideActionView(shouldShow: false)
        }
    }
    func presentDirections() {
        guard let trip = trip else { return }
        let destinationString = "Destination: \(trip.destinationCoordinates.latitude), \(trip.destinationCoordinates.longitude)"
        let pickupString = "Pickup: \(trip.pickupCoordinates.latitude), \(trip.pickupCoordinates.longitude)"
        presentAlertController(withTitle: destinationString, withMessage: pickupString)
    }
}

//MARK: - PickupControllerDelegate

extension HomeController: PickupControllerDelegate {
    
    func didAcceptTrip(_ trip: Trip) {
        self.trip = trip
        
        mapView.addAnnotationAndSelect(forCoordinate: trip.pickupCoordinates)
        setCustomRegion(withType: .pickup, withCoordinates: trip.pickupCoordinates)
        
        let placemark = MKPlacemark(coordinate: trip.pickupCoordinates)
        let mapItem = MKMapItem(placemark: placemark)
        generatePolyline(toDestionation: mapItem)

        mapView.zoomToFit(annotations: mapView.annotations)
        
        self.dismiss(animated: true) {
            Service.shared.fetchUserData(uid: trip.passengerUid) { passenger in
                self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: passenger)
            }
        }
    }
    
}





