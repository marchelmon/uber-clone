//
//  RideActionView.swift
//  uber-clone
//
//  Created by marchelmon on 2021-05-22.
//

import UIKit
import MapKit

class RideActionView: UIView {

    //MARK: - Properties
    
    var destination: MKPlacemark? {
        didSet {
            titleLabel.text = destination?.name
            addressLabel.text = destination?.address
        }
    }
    
    private let titleLabel: UILabel = {
       let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.text = "Kaffemannen"
        label.textAlignment = .center
        return label
    }()
    
    private let addressLabel: UILabel = {
       let label = UILabel()
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.text = "Lerduvevägen 14, 436 51 Göteborg"
        return label
    }()
    
    private lazy var infoView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 30)
        label.textColor = .white
        label.text = "X"
        
        view.addSubview(label)
        label.centerX(inView: view)
        label.centerY(inView: view)
        
        return view
    }()
    
    private let uberXLabel: UILabel = {
       let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.text = "Uber X"
        label.textAlignment = .center
        return label
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Confirm UBER X", for: .normal)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        return button
    }()
    
    //MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        addShadow()
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, addressLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.distribution = .fillEqually
        
        addSubview(stack)
        stack.centerX(inView: self)
        stack.anchor(top: topAnchor, paddingTop: 12)
        
        addSubview(infoView)
        infoView.centerX(inView: self)
        infoView.anchor(top: stack.bottomAnchor, paddingTop: 16)
        infoView.setDimensions(width: 60, height: 60)
        infoView.layer.cornerRadius = 60 / 2
        
        addSubview(uberXLabel)
        uberXLabel.anchor(top: infoView.bottomAnchor, paddingTop: 8)
        uberXLabel.centerX(inView: self)
        
        let separatorView = UIView()
        separatorView.backgroundColor = .lightGray
        addSubview(separatorView)
        separatorView.anchor(top: uberXLabel.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 4, height: 0.75)
        
        addSubview(actionButton)
        actionButton.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: 12, paddingBottom: 40, paddingRight: 12, height: 50)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @objc func actionButtonPressed() {
        print("#hej")
    }
    
    
}
