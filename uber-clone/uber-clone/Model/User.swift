//
//  User.swift
//  uber-clone
//
//  Created by marchelmon on 2021-05-12.
//

import Foundation
import CoreLocation

enum AccountType: Int {
    case passenger
    case driver
}

struct User {
    let uid: String
    let fullname: String
    let email: String
    var accountType: AccountType
    var location: CLLocation?
    var home: String?
    var work: String?
    
    var firstInitial: String { return String(fullname.prefix(1)) }

    init(uid: String, data: [String: Any]) {
        self.uid = uid
        fullname = data["fullname"] as? String ?? "John Doe"
        email = data["email"] as? String ?? "John Doe"
        home = data["home"] as? String
        work = data["work"] as? String
        
        if let index = data["accountType"] as? Int {
            self.accountType = AccountType(rawValue: index) ?? .driver
        } else {
            self.accountType = .driver
        }
    }
    
    
    
}
