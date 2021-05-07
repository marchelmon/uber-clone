//
//  LoginController.swift
//  uber-clone
//
//  Created by marchelmon on 2021-05-06.
//

import UIKit

class LoginController: UIViewController {
    
    //MARK: - Properties
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "UBER"
        label.font = UIFont(name: "Avenir-Light", size: 36)
        label.textColor = UIColor(white: 1, alpha: 0.8)
        return label
    }()
    
    private let emailTextField = UITextField().textField(placeholder: "Email")
    private let passwordTextField = UITextField().textField(placeholder: "Password", isSecureText: true)
        
    private lazy var emailContainerView = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_mail_outline_white_2x"), textField: emailTextField)
    private lazy var passwordContainerView = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_lock_outline_white_2x"), textField: passwordTextField)
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.setTitleColor(UIColor(white: 1, alpha: 0.5), for: .normal)
        button.backgroundColor = UIColor.mainBlueInt
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20 )
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }()
    
    private let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(
            string: "Don't have an account",
            attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
                         NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        attributedTitle.append(NSAttributedString(
            string: " Sign up",
            attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16),
                         NSAttributedString.Key.foregroundColor: UIColor.mainBlueInt]))
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        button.addTarget(self, action: #selector(handleShowSignUp), for: .touchUpInside)
        
        return button
    }()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        
    }
    
    //MARK: - Actions
    
    @objc func handleShowSignUp() {
        let controller = RegistrationController()
        
        navigationController?.pushViewController(controller, animated: true)
        
        
    }
    
    //MARK: - Helpers
    
    func configureUI() {
        view.backgroundColor = UIColor.backgroundColor
        configureNavigationBar()
        
        view.addSubview(titleLabel)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 50)
        titleLabel.centerX(inView: view)
        
        let stack = UIStackView(arrangedSubviews: [emailContainerView, passwordContainerView, loginButton])
        stack.axis = .vertical
        stack.spacing = 24
        stack.distribution = .fillEqually
        
        view.addSubview(stack)
        stack.anchor(top: titleLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 40, paddingLeft: 16, paddingRight: 16)
        
        view.addSubview(signUpButton)
        signUpButton.centerX(inView: view)
        signUpButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, height: 32)
        
    }
    
    func configureNavigationBar() {
        navigationController?.navigationBar.isHidden = true
        navigationController?.navigationBar.barStyle = .black
    }
    
}
