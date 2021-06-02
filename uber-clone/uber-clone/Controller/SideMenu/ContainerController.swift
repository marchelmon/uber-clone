//
//  ContainerController.swift
//  uber-clone
//
//  Created by marchelmon on 2021-06-01.
//

import UIKit

class ContainerController: UIViewController {
    
    //MARK: - Properties
    
    private let homeController = HomeController()
    private let menuController = MenuController()
        
    var menuIsExpanded: Bool = false
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        homeController.delegate = self

        configureHomeController()
        configureMenuController()
    }
    
    
    //MARK: - Actions
    
    
    //MARK: - Helpers
    
    func configureHomeController() {
        addChild(homeController)
        homeController.didMove(toParent: self)
        view.addSubview(homeController.view)
    }
    
    func configureMenuController() {
        addChild(menuController)
        menuController.didMove(toParent: self)
        view.insertSubview(menuController.view, at: 0)
    }
    
    func animateMenu(shouldExpand: Bool) { 
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            self.homeController.view.frame.origin.x = shouldExpand ? self.view.frame.width - 80 : 0
        }, completion: nil)
    }
    
}

extension ContainerController: HomeControllerDelegate {
    func handleMenuToggle() {
        menuIsExpanded.toggle()
        animateMenu(shouldExpand: menuIsExpanded)
        
    }
}
