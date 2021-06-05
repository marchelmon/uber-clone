//
//  MenuController.swift
//  uber-clone
//
//  Created by marchelmon on 2021-06-01.
//

import UIKit

private let menuCellIdentifier = "MenuCell"

enum MenuOptions: Int, CaseIterable, CustomStringConvertible {
    case yourTrips
    case settings
    case logout
        
    var description: String {
        switch self {
        case .yourTrips: return "Your trips"
        case .settings: return "Settings"
        case .logout: return "Logout"
        }
    }
}

protocol MenuControllerDelegate: class {
    func didSelect(option: MenuOptions)
}

class MenuController: UIViewController {
    
    //MARK: - Properties
    
    private let user: User
    
    weak var delegate: MenuControllerDelegate?
    
    private let tableView = UITableView()
    
    private lazy var menuHeader: MenuHeader = {
        let frame = CGRect(x: 0, y: 0, width: self.view.frame.width - 80, height: 200)
        let view = MenuHeader(user: self.user, frame: frame)
        
        return view
    } ()
    
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
        view.backgroundColor = .white
        
        configureTableView()
    }
    
    
    //MARK: - Actions
    
    
    //MARK: - Helpers
    
    func configureTableView() {
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = 60
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: menuCellIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableHeaderView = menuHeader
        
        view.addSubview(tableView)
        tableView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor)
    }
    
}


//MARK: - UITableViewDelegate and UITableViewDataSource

extension MenuController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MenuOptions.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: menuCellIdentifier, for: indexPath)
        
        guard let option = MenuOptions(rawValue: indexPath.row) else { return UITableViewCell() }
        cell.textLabel?.text = option.description
        cell.selectionStyle = .none

        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let option = MenuOptions(rawValue: indexPath.row) else { return }
        delegate?.didSelect(option: option)
    }
    
}

