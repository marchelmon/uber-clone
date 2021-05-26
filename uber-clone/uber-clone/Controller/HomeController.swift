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

class HomeController: UIViewController {
    
    //MARK: - Properties
    
    private let mapView = MKMapView()
    
    private let locationManager: CLLocationManager = LocationHandler.shared.locationManager
    
    private let inputActivationView = LocationInputActivationView()
    private let rideActionView = RideActionView()
    private let locationInputView = LocationInputView()
    private let tableView = UITableView()
    private var searchResults = [MKPlacemark]()
    private final let locationInputViewHeight: CGFloat = 200
    private final let rideActionViewHeight: CGFloat = 300
    private var actionButtonConfig = ActionButtonConfig()
    private var route: MKRoute?
    
    private var user: User? {
        didSet { locationInputView.user = user }
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
        
        inputActivationView.delegate = self
        locationInputView.delegate = self
        rideActionView.delegate = self
        
        enableLocationServices()
        checkIfUserIsLoggedIn()
    
    }
    
    //MARK: - Actions
    
    @objc func actionButtonPressed() {
        switch actionButtonConfig {
        case .showMenu:
            print("Handle show menu")
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
    
    //MARK: - API
    
    func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Service.shared.fetchUserData(uid: uid) { user in
            self.user = user
        }
    }
    
    func fetchDrivers() {
        guard let location = locationManager.location else { return }
        Service.shared.fetchDrivers(userLocation: location) { driver in
            guard let coordinate = driver.location?.coordinate else { return }
            let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)

            var driverIsVisable: Bool {
                return self.mapView.annotations.contains { annotation -> Bool in
                    guard let driverAnnotation = annotation as? DriverAnnotation else { return false }
                    if driverAnnotation.uid == driver.uid {
                        driverAnnotation.updateAnnotationPosition(withCoordinate: coordinate)
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
    
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser == nil {
            presentLoginController()
        } else {
            configure()
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            presentLoginController()
        } catch {
            print("DEBUG: ERROR logging out")
        }
    }
    
    //MARK: - Helpers
    
    func presentLoginController() {
        DispatchQueue.main.async {
            let controller = UINavigationController(rootViewController: LoginController())
            controller.modalPresentationStyle = .fullScreen
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    func configure() {
        configureUI()
        fetchUserData()
        fetchDrivers()
    }
    
    func configureUI() {
        configureMapView()
        configureTableView()
        configureRideActionView()
        
        view.addSubview(actionButton)
        actionButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingTop: 16, paddingLeft: 20, width: 30, height: 30)
        
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
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: CLLocationDistance(exactly: 10000)!, longitudinalMeters: CLLocationDistance(exactly: 10000)!)
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
    
    func animateRideActionView(shouldShow: Bool, destination: MKPlacemark? = nil) {
        let yOrigin = self.view.frame.height - (shouldShow ? self.rideActionViewHeight : 0)
        
        if shouldShow {
            guard let destination = destination else { return }
            self.rideActionView.destination = destination
        }
        
        UIView.animate(withDuration: 0.3) {
            self.rideActionView.frame.origin.y = yOrigin
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
    
}

//MARK: - MKMapViewDelegate

extension HomeController: MKMapViewDelegate {
    
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

//MARK: - LocationServices

extension HomeController {
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
        return "test"
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2 : searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! LocationCell
        
        if indexPath.section == 1 {
            cell.placemark = searchResults[indexPath.row]
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPlacemark = self.searchResults[indexPath.row]
        
        configureActionButton(config: .dismissActionView)
        
        let destination = MKMapItem(placemark: selectedPlacemark)
        generatePolyline(toDestionation: destination)
        
        dismissLocationView { _ in
            let annotation = MKPointAnnotation()
            annotation.coordinate = selectedPlacemark.coordinate
            self.mapView.addAnnotation(annotation)
            self.mapView.selectAnnotation(annotation, animated: true)
         
            let annotations = self.mapView.annotations.filter({ !$0.isKind(of: DriverAnnotation.self) })
            
            self.mapView.zoomToFit(annotations: annotations)
            
            self.animateRideActionView(shouldShow: true, destination: selectedPlacemark)
            
        }
    }
}

//MARK: - RideActionViewDelegate

extension HomeController: RideActionViewDelegate {
    func uploadTrip(_ view: RideActionView) {
        guard let pickupCoordinates = locationManager.location?.coordinate else { return }
        guard let destinationCoordinates = view.destination?.coordinate else { return }
        
        Service.shared.uploadTrip(pickupCoordinates, destinationCoordinates: destinationCoordinates) { error in
            if let error = error {
                print("No trip uploaded error: \(error.localizedDescription)")
                return
            }
            
            print("TRIPS upload ja")
        }
    }
}





