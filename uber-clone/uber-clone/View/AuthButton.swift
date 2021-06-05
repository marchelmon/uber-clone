//
//  AuthButton.swift
//  uber-clone
//
//  Created by marchelmon on 2021-05-07.
//

import UIKit

class AuthButton: UIButton {

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setTitleColor(UIColor(white: 1, alpha: 0.9), for: .normal)
        backgroundColor = UIColor.mainBlueTint
        layer.cornerRadius = 5
        heightAnchor.constraint(equalToConstant: 50).isActive = true
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
