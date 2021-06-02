//
//  MenuController.swift
//  uber-clone
//
//  Created by marchelmon on 2021-06-01.
//

import UIKit

private let menuCellIdentifier = "MenuCell"

class MenuController: UIViewController {
    
    //MARK: - Properties
    
    private let tableView = UITableView()
    
    private lazy var menuHeader: MenuHeader = {
        let view = MenuHeader(frame: CGRect(x: 0, y: 0, width: self.view.frame.width - 80, height: 140))
        
        return view
    } ()
    
    //MARK: - Lifecycle
    
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
        3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: menuCellIdentifier, for: indexPath)
        cell.textLabel?.text = "Menu Option"
        return cell
    }

}

