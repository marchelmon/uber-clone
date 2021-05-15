//
//  User.swift
//  uber-clone
//
//  Created by marchelmon on 2021-05-12.
//

import Foundation
import CoreLocation

struct User {
    let uid: String
    let fullname: String
    let email: String
    let accountType: Int
    var location: CLLocation?

    init(uid: String, data: [String: Any]) {
        self.uid = uid
        fullname = data["fullname"] as? String ?? "John Doe"
        email = data["email"] as? String ?? "John Doe"
        accountType = data["accountType"] as? Int ?? 0
    }
    
}
