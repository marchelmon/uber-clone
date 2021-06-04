//
//  RegistrationController.swift
//  uber-clone
//
//  Created by marchelmon on 2021-05-07.
//

import UIKit
import Firebase
import FirebaseFirestore
import GeoFire

class RegistrationController: UIViewController {
    
    //MARK: - Properties
    
    private var location = LocationHandler.shared.locationManager.location
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "!UBER"
        label.font = UIFont(name: "Avenir-Light", size: 36)
        label.textColor = UIColor(white: 1, alpha: 0.8)
        return label
    }()
    
    private let emailTextField = UITextField().textField(placeholder: "Email")
    private let nameTextField = UITextField().textField(placeholder: "Full name")
    private let passwordTextField = UITextField().textField(placeholder: "Password")
            
    private lazy var emailContainerView = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_mail_outline_white_2x"), textField: emailTextField)
    private lazy var nameContainerView = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_person_outline_white_2x"), textField: nameTextField)
    private lazy var passwordContainerView = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_lock_outline_white_2x"), textField: passwordTextField)
    
    private let accountSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Rider", "Driver"])
        sc.backgroundColor = .backgroundColor
        sc.tintColor = UIColor(white: 1, alpha: 0.87)
        sc.selectedSegmentIndex = 0
        return sc
    }()

    private lazy var accountTypeContainerView = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_account_box_white_2x"), segmentedControl: accountSegment, height: 80)
    
    private let registrationButton: AuthButton = {
        let button = AuthButton(type: .system)
        button.setTitle("Sign up", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.addTarget(self, action: #selector(handleRegistration), for: .touchUpInside)
        return button
    }()
    
    private let goToLoginButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(
            string: "Already have an account",
            attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
                         NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        attributedTitle.append(NSAttributedString(
            string: " Login",
            attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16),
                         NSAttributedString.Key.foregroundColor: UIColor.mainBlueTint]))
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        button.addTarget(self, action: #selector(handleShowLogin), for: .touchUpInside)
        
        return button
    }()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()

    }
    
    
    //MARK: - Actions
    
    @objc func handleRegistration() {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        guard let fullName = nameTextField.text else { return }
        let accountTypeIndex = accountSegment.selectedSegmentIndex
        
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error {
                print("DEBUG: \(error.localizedDescription)")
                return
            }
            guard let uid = result?.user.uid else { return }
            
            let userData = ["email": email, "fullname": fullName, "accountType": accountTypeIndex] as [String : Any]
            
            if accountTypeIndex == 1 {
                
                guard let latitude = self.location?.coordinate.latitude else { return }
                guard let longitude = self.location?.coordinate.longitude else { return }
                
                let hash = GFUtils.geoHash(forLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                                
                let locationData: [String: Any] = [
                    "geohash": hash,
                    "lat": latitude,
                    "lng": longitude
                ]
                
                COLLECTION_DRIVER_LOCATIONS.document(uid).setData(locationData) { error in
                    if let error = error {
                        print("Error updating user location: \(error.localizedDescription)")
                        return
                    }
                    self.addUserToFirestoreAndShowHomeController(uid: uid, userData: userData)
                }
            } else {
                self.addUserToFirestoreAndShowHomeController(uid: uid, userData: userData)
            }
        }
    }
    
    @objc func handleShowLogin() {
        navigationController?.popViewController(animated: true)
    }
    
    //MARK: - Helpers
    
    func addUserToFirestoreAndShowHomeController(uid: String, userData: [String: Any]) {
        COLLECTION_USERS.document(uid).setData(userData) { error in
            if let error = error {
                print("DEBUG register: \(error.localizedDescription)")
                return
            }
            let sceneDelegate = UIApplication.shared.connectedScenes.first!.delegate as? SceneDelegate
            guard let controller = sceneDelegate?.window?.rootViewController as? ContainerController else { return }
            controller.configure()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func configureUI() {
        view.backgroundColor = UIColor.backgroundColor
        
        view.addSubview(titleLabel)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 50)
        titleLabel.centerX(inView: view)
                
        let stack = UIStackView(arrangedSubviews: [emailContainerView, nameContainerView, passwordContainerView, accountTypeContainerView, registrationButton])
        stack.axis = .vertical
        stack.spacing = 24
        stack.distribution = .fill
        
        view.addSubview(stack)
        stack.anchor(top: titleLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 40, paddingLeft: 16, paddingRight: 16)
        
        view.addSubview(goToLoginButton)
        goToLoginButton.centerX(inView: view)
        goToLoginButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, height: 32)
        
    }
    
}
