//
//  User.swift
//  uber-clone
//
//  Created by marchelmon on 2021-05-12.
//

import Foundation

struct User {
    let fullname: String
    let email: String
    let accountType: Int

    init(data: [String: Any]) {
        fullname = data["fullname"] as? String ?? "John Doe"
        email = data["email"] as? String ?? "John Doe"
        accountType = data["accountType"] as? Int ?? 0
    }
    
}
