//
//  AddLocationController.swift
//  uber-clone
//
//  Created by marchelmon on 2021-06-02.
//

import UIKit
import MapKit

private let cellIdentifier = "Cell"

protocol AddLocationControllerDelegate: class {
    func updateFavoriteLocation(locationString: String, locationType: LocationType)
}

class AddLocationController: UITableViewController {
    
    //MARK: - Properties
    
    weak var delegate: AddLocationControllerDelegate?
    
    private let searchBar = UISearchBar()
    private let searchCompleter = MKLocalSearchCompleter()
    private let locationType: LocationType
    private let location: CLLocation
    private var searchResults = [MKLocalSearchCompletion]() {
        didSet { tableView.reloadData() }
    }

    //MARK: - Lifecycle
    
    init(locationType: LocationType, location: CLLocation) {
        self.locationType = locationType
        self.location = location
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSearchBar()
        configureTableView()
        configureSearchCompleter()
        
    }
    
    //MARK: - Actions
    
    
    //MARK: - Helpers
    
    func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 60
        tableView.addShadow()
    }
    
    func configureSearchBar() {
        searchBar.sizeToFit()
        searchBar.delegate = self
        navigationItem.titleView = searchBar
    }
    
    func configureSearchCompleter() {
        searchCompleter.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 100, longitudinalMeters: 100)
        searchCompleter.delegate = self
    }
    
}

//MARK: - UITableViewDelegate/UITableViewDataSource
extension AddLocationController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        let result = searchResults[indexPath.row]
        cell.textLabel?.text = result.title
        cell.detailTextLabel?.text = result.subtitle
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = searchResults[indexPath.row]
        let locationString = "\(result.title) \(result.subtitle)"
        delegate?.updateFavoriteLocation(locationString: locationString, locationType: locationType)
    }
}


//MARK: - UISearchBarDelegate

extension AddLocationController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchCompleter.queryFragment = searchText
    }
}

//MARK: - MKLocalSearchCompleterDelegate

extension AddLocationController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        //tableView.reloadData()
    }
}
