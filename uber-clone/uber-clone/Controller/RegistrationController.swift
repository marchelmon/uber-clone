//
//  RegistrationController.swift
//  uber-clone
//
//  Created by marchelmon on 2021-05-07.
//

import UIKit

class RegistrationController: UIViewController {
    
    //MARK: - Properties
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "UBER"
        label.font = UIFont(name: "Avenir-Light", size: 36)
        label.textColor = UIColor(white: 1, alpha: 0.8)
        return label
    }()
    
    private let emailTextField = UITextField().textField(placeholder: "Email")
    private let nameTextField = UITextField().textField(placeholder: "Full name")
    private let passwordTextField = UITextField().textField(placeholder: "Password", isSecureText: true)
            
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
                         NSAttributedString.Key.foregroundColor: UIColor.mainBlueInt]))
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
    
    @objc func handleShowLogin() {
        navigationController?.popViewController(animated: true)
    }
    
    //MARK: - Helpers
    
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
