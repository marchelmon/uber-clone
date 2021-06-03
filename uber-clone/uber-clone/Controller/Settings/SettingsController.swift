//
//  SettingsController.swift
//  uber-clone
//
//  Created by marchelmon on 2021-06-02.
//

import UIKit

private let locationCellIdentifier = "LocationCell"

enum LocationType: Int, CaseIterable, CustomStringConvertible {
    case home
    case work
    
    var description: String {
        switch self {
        case .home: return "Home"
        case .work: return "Work"
        }
    }
    
    var subtitle: String {
        switch self {
        case .home: return "Add Home"
        case .work: return "Add Work"
        }
    }
}

protocol SettingsControllerDelegate: class {
    func updateUser(_ controller: SettingsController)
}

class SettingsController: UITableViewController {
    
    //MARK: - Properties
    
    var user: User
    
    weak var delegate: SettingsControllerDelegate?
    
    private var userInfoUpdated: Bool = false
    
    private let locationManager = LocationHandler.shared.locationManager
    
    private lazy var infoHeader: UserInfoHeader = {
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 100)
        let view = UserInfoHeader(user: user, frame: frame)
        return view
    }()
    
    //MARK: - Lifecycle
    
    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar()
        configureTableView()
    }
    
    
    //MARK: - Actions
    
    @objc func handleDismiss() {
        if userInfoUpdated {
            self.delegate?.updateUser(self)
            userInfoUpdated = false
        }
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Helpers
    
    func locationText(forType type: LocationType) -> String{
        switch type {
        case .home:
            return user.home ?? type.subtitle
        case .work:
            return user.work ?? type.subtitle
        }
    }
    
    func configureTableView() {
        tableView.rowHeight = 60
        tableView.register(LocationCell.self, forCellReuseIdentifier: locationCellIdentifier)
        tableView.backgroundColor = .white
        tableView.tableHeaderView = infoHeader
        tableView.tableFooterView = UIView()
    }
    
    func configureNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barStyle = .black
        navigationItem.title = "Settings"
        navigationController?.navigationBar.barTintColor = .backgroundColor
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "baseline_clear_white_36pt_2x").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleDismiss))
    }
}

//MARK: - UITableViewDelegate/UITablViewDataSource

extension SettingsController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LocationType.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .black
        
        let title = UILabel()
        title.text = "Favorites"
        title.textColor = .white
        title.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(title)
        title.centerY(inView: view, leftAnchor: view.leftAnchor, paddingLeft: 16)
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: locationCellIdentifier) as! LocationCell
        
        guard let locationType = LocationType(rawValue: indexPath.row) else { return cell }
        cell.titleLabel.text = locationType.description
        cell.addressLabel.text = locationText(forType: locationType)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let locationType = LocationType(rawValue: indexPath.row) else { return }
        guard let location = locationManager?.location else { return }
        let controller = AddLocationController(locationType: locationType, location: location)
        controller.delegate = self
        let nav = UINavigationController(rootViewController: controller)
        present(nav, animated: true, completion: nil)
    }
    
}

extension SettingsController: AddLocationControllerDelegate {
    func updateFavoriteLocation(locationString: String, locationType: LocationType) {
        PassengerService.shared.saveFavoriteLocation(locationString: locationString, locationType: locationType) { error in
            self.dismiss(animated: true, completion: nil)
            self.userInfoUpdated = true
            
            switch locationType {
            case .home:
                self.user.home = locationString
            case .work:
                self.user.work = locationString
            }
            self.tableView.reloadData()
        }
    }
}





