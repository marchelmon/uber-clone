//
//  Service.swift
//  uber-clone
//
//  Created by marchelmon on 2021-05-12.
//

import Firebase
import FirebaseFirestore

let COLLECTION_USERS = Firestore.firestore().collection("users")

struct Service {
    
    static let shared = Service()
    
    func fetchUserData(completion: @escaping(User) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { print("Not Authenticated"); return }
        COLLECTION_USERS.document(uid).getDocument { (snapshot, error) in
            if let error = error {
                print("DEBUG: fetch users: \(error.localizedDescription)")
                return
            }
            if let snapshot = snapshot {
                if let userData = snapshot.data() {
                    let user = User(data: userData)
                    completion(user)
                }
            }
        }
    }
    
}
