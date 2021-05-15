//
//  LocationInputView.swift
//  uber-clone
//
//  Created by marchelmon on 2021-05-11.
//

import UIKit

protocol LocationInputViewDelegate: class {
    func dismissLocationInputView()
    func executeSearch(query: String)
}

class LocationInputView: UIView {

    //MARK: - Properties
    
    var user: User? {
        didSet { titleLabel.text = user?.fullname }
    }
    
    weak var delegate: LocationInputViewDelegate?
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp-1").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBackTapped), for: .touchUpInside)
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Name here"
        label.font = UIFont(name: "Avenir-Light", size: 16)
        label.textColor = .darkGray
        return label
    }()
    
    private let startLocationIndicatorView: UIView = {
       let view = UIView()
        view.backgroundColor = .lightGray
        view.setDimensions(width: 6, height: 6)
        view.layer.cornerRadius = 6/2
        return view
    }()
    
    private let linkingView: UIView = {
       let view = UIView()
        view.backgroundColor = .darkGray
        return view
    }()
    
    private let destinationIndicatorView: UIView = {
       let view = UIView()
        view.backgroundColor = .black
        view.setDimensions(width: 6, height: 6)
        return view
    }()
    
    private lazy var startingLocationTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Current location"
        tf.backgroundColor = .systemGroupedBackground
        tf.isEnabled = false
        tf.font = UIFont.systemFont(ofSize: 14)
        
        let paddingView = UIView()
        paddingView.setDimensions(width: 8, height: 30)
        tf.leftView = paddingView
        tf.leftViewMode = .always
        
        return tf
    } ()
    
    private lazy var destinationTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter destination"
        tf.backgroundColor = .lightGray
        tf.returnKeyType = .search
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.delegate = self
        
        let paddingView = UIView()
        paddingView.setDimensions(width: 8, height: 30)
        tf.leftView = paddingView
        tf.leftViewMode = .always
        
        return tf
    } ()
    
    
    //MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        addShadow()
        
        addSubview(backButton)
        backButton.anchor(top: topAnchor, left: leftAnchor, paddingTop: 44, paddingLeft: 16, width: 24, height: 24)
        
        addSubview(titleLabel)
        titleLabel.centerY(inView: backButton)
        titleLabel.centerX(inView: self)
        
        addSubview(startingLocationTextField)
        startingLocationTextField.anchor(top: backButton.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 4, paddingLeft: 40, paddingRight: 40, height: 30)
        
        addSubview(destinationTextField)
        destinationTextField.anchor(top: startingLocationTextField.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 12, paddingLeft: 40, paddingRight: 40, height: 30)
        
        addSubview(startLocationIndicatorView)
        startLocationIndicatorView.centerY(inView: startingLocationTextField, leftAnchor: leftAnchor, paddingLeft: 20)

        addSubview(destinationIndicatorView)
        destinationIndicatorView.centerY(inView: destinationTextField, leftAnchor: leftAnchor, paddingLeft: 20)
        
        addSubview(linkingView)
        linkingView.centerX(inView: startLocationIndicatorView)
        linkingView.anchor(top: startLocationIndicatorView.bottomAnchor, bottom: destinationIndicatorView.topAnchor, paddingTop: 4, paddingBottom: 4, width: 0.5)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Actions
    
    @objc func handleBackTapped() {
        delegate?.dismissLocationInputView()
    }
    
    
}

//MARK: - UITextFieldDelegate

extension LocationInputView: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let query = textField.text else { return false }
        delegate?.executeSearch(query: query)
        return true
    }
    
}
