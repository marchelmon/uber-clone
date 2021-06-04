//
//  MenuHeader.swift
//  uber-clone
//
//  Created by marchelmon on 2021-06-02.
//

import UIKit

class MenuHeader: UIView {
    
    //MARK: - Properties

    private let user: User
    
    private lazy var profileImageView: UIImageView = {
        let iv = UIImageView(image: #imageLiteral(resourceName: "ic_person_outline_white_2x").withRenderingMode(.alwaysOriginal))
        iv.backgroundColor = .black
        iv.layer.cornerRadius = 64 / 2
        return iv
    }()
    
//    private lazy var profileImageView: UIView = {
//        let view = UIView()
//        view.backgroundColor = .darkGray
//        view.layer.cornerRadius = 64 / 2
//        let initialLabel = UILabel()
//        initialLabel.text = user.firstInitial
//        initialLabel.textColor = .white
//        initialLabel.font = UIFont.systemFont(ofSize: 40)
//
//        view.addSubview(initialLabel)
//        initialLabel.centerX(inView: view)
//        initialLabel.centerY(inView: view)
//
//        return view
//    }()
    
    private lazy var fullnameLabel: UILabel = {
        let label = UILabel()
        label.text = user.fullname
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    private lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.text = user.email
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.numberOfLines = 2
        return label
    }()
    
    //MARK: - Lifecycle
    
    init(user: User, frame: CGRect) {
        self.user = user
        super.init(frame: frame)

        addSubview(profileImageView)
        profileImageView.anchor(top: safeAreaLayoutGuide.topAnchor, left: leftAnchor, paddingTop: 10, paddingLeft: 12, width: 64, height: 64)
        
        let stack = UIStackView(arrangedSubviews: [fullnameLabel, emailLabel])
        stack.distribution = .fillEqually
        stack.spacing = 4
        stack.axis = .vertical
        addSubview(stack)
        stack.centerY(inView: profileImageView, leftAnchor: profileImageView.rightAnchor, paddingLeft: 12)
        
        backgroundColor = .backgroundColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Actions

    
    //MARK: - Helpers
    
}
