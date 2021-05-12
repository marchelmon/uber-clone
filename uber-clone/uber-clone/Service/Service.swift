//
//  Service.swift
//  uber-clone
//
//  Created by marchelmon on 2021-05-12.
//

import Firebase
import FirebaseFirestore

struct User {
    let uid: String
    let fullname: String
    let email: String
    let accountType: Int

    init(data: [String: Any]) {
        uid = data["uid"] as? String ?? "No uid found"
        fullname = data["fullname"] as? String ?? "John Doe"
        email = data["email"] as? String ?? "John Doe"
        accountType = data["accountType"] as? Int ?? 0
    }
    
}

let COLLECTION_USERS = Firestore.firestore().collection("users")

struct Service {
    
    static let shared = Service()
    
    func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { print("Not Authenticated"); return }
        COLLECTION_USERS.document(uid).getDocument { (snapshot, error) in
            if let error = error {
                print("DEBUG: fetch users: \(error.localizedDescription)")
                return
            }
            if let snapshot = snapshot {
                if var userData = snapshot.data() {
                    userData["uid"] = uid
                    let user = User(data: userData)
                    print("USER: \(user)")
                }
            }
        }
    }
    
}
