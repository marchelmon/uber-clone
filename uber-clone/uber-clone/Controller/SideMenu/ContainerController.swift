//
//  ContainerController.swift
//  uber-clone
//
//  Created by marchelmon on 2021-06-01.
//

import UIKit
import Firebase

class ContainerController: UIViewController {
    
    //MARK: - Properties
    
    var user: User? {
        didSet {
            guard let user = user else { return }
            configureHomeController(withUser: user)
            configureMenuController(withUser: user)
        }
    }
    
    private var homeController = HomeController()
    private var menuController: MenuController!
        
    var menuIsExpanded: Bool = false
    
    private lazy var blackView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoggedIn()
    }
    
    override var prefersStatusBarHidden: Bool {
        return menuIsExpanded
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    //MARK: - Actions
    
    @objc func dismissMenu() {
        menuIsExpanded.toggle()
        animateMenu(shouldExpand: menuIsExpanded)
    }
    
    //MARK: - API
    
    func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Service.shared.fetchUserData(uid: uid) { user in
            self.user = user
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            homeController.presentLoginController()
        } catch {
            print("DEBUG: ERROR logging out")
        }
    }
    
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser == nil {
            homeController.presentLoginController()
        } else {
            fetchUserData()
        }
    }
    
    //MARK: - Helpers
    
    func configure() {
        view.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        fetchUserData()
    }
    
    func configureBlackView() {
        blackView.frame = self.view.bounds
        blackView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        blackView.alpha = 0
        
        view.addSubview(blackView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissMenu))
        blackView.addGestureRecognizer(tap)
    }
    
    func configureHomeController(withUser user: User) {
        homeController.user = user
        addChild(homeController)
        homeController.didMove(toParent: self)
        view.addSubview(homeController.view)
        homeController.delegate = self
    }
    
    func configureMenuController(withUser user: User) {
        menuController = MenuController(user: user)
        addChild(menuController)
        menuController.didMove(toParent: self)
        view.insertSubview(menuController.view, at: 0)
        menuController.delegate = self
        configureBlackView()
    }
    
    func animateMenu(shouldExpand: Bool, completion: ((Bool) -> Void)? = nil) {
        self.blackView.alpha = shouldExpand ? 1 : 0

        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            let menuExpandedOrigin = self.view.frame.width - 80

            self.homeController.view.frame.origin.x = shouldExpand ? menuExpandedOrigin : 0
            self.blackView.frame.origin.x = shouldExpand ? menuExpandedOrigin : 0
        }, completion: completion)
        
        animateStatusBar()
    }
    
    func animateStatusBar() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        }, completion: nil)

    }
}

//MARK: - HomeControllerDelegate

extension ContainerController: HomeControllerDelegate {
    func handleMenuToggle() {
        menuIsExpanded.toggle()
        animateMenu(shouldExpand: menuIsExpanded)
        
    }
}

//MARK: - MenuControllerDelegate

extension ContainerController: MenuControllerDelegate {
    func didSelect(option: MenuOptions) {
        menuIsExpanded.toggle()
        animateMenu(shouldExpand: menuIsExpanded) { _ in
            switch option {
            case .yourTrips:
                break
            case .settings:
                guard let user = self.user else { return }
                let controller = SettingsController(user: user)
                controller.delegate = self
                let nav = UINavigationController(rootViewController: controller)
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
                
            case .logout:
                let alert = UIAlertController(title: nil, message: "Are you sure you want to log out?", preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
                    self.signOut()
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}

//MARK: - SettingsControllerDelegate

extension ContainerController: SettingsControllerDelegate {
    func updateUser(_ controller: SettingsController) {
        self.user = controller.user
    }
}
