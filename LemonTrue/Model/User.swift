//  MIT License

//  Copyright (c) 2017 Haik Aslanyan

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.


import Foundation
import UIKit
import Firebase
import FBSDKLoginKit

class User: NSObject {
    
    //MARK: Properties
    let name: String
    let email: String
    let id: String
    var profilePic: UIImage
    let nickName: String
    
    //MARK: Methods
    class func registerUser(withName: String, email: String, password: String, profilePic: UIImage, completion: @escaping (Bool) -> Swift.Void) {
        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
            if error == nil {
               // user?.sendEmailVerification(completion: nil)
                let storageRef = Storage.storage().reference().child("usersProfilePics").child(user!.user.uid)
                let imageData = UIImageJPEGRepresentation(profilePic, 0.1)
                storageRef.putData(imageData!, metadata: nil, completion: { (metadata, err) in
                    if err == nil {
                        
                        // Fetch the download URL
                        storageRef.downloadURL { url, error in
                            if let error = error {
                                // Handle any errors
                            } else {
                                
                                let values = ["name": withName, "email": email, "profilePicLink": (url?.absoluteString)! + "?height=512"]
                                Database.database().reference().child("users").child((user?.user.uid)!).child("credentials").updateChildValues(values, withCompletionBlock: { (errr, _) in
                                    if errr == nil {
                                        let userInfo = ["email" : email, "password" : password]
                                        UserDefaults.standard.set(userInfo, forKey: "userInformation")
                                        completion(true)
                                    }
                                })
                                // Get the download URL for 'images/stars.jpg'
                            }
                        }
                        
                   
                    }
                })
            }
            else {
                completion(false)
            }
        })
    }
    
    
    
    
   class func loginUser(withEmail: String, password: String, completion: @escaping (Bool) -> Swift.Void) {
        Auth.auth().signIn(withEmail: withEmail, password: password, completion: { (user, error) in
            if error == nil {
                let userInfo = ["email": withEmail, "password": password]
                UserDefaults.standard.set(userInfo, forKey: "userInformation")
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    
    
    class func loginUser(credential: AuthCredential, completion: @escaping (Bool) -> Swift.Void) {
        
        
        Auth.auth().signIn(with: credential, completion: { (user, error) in
            if let error = error {
                completion(false)
                print("Login error: \(error.localizedDescription)")
                return
            }
            
            var email = user?.email
            if(email == nil){
                email = "sememail@sememail.com"
            }
            let values = ["name": user?.displayName, "email": email, "profilePicLink": user?.photoURL?.absoluteString]
            Database.database().reference().child("users").child((user?.uid)!).child("credentials").updateChildValues(values, withCompletionBlock: { (errr, _) in
                if errr == nil {
                  //  completion(true)
                }
            })
            
            completion(true)
            
        })
        

    }
    
    class func logOutUser(completion: @escaping (Bool) -> Swift.Void) {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: "userInformation")
            completion(true)
        } catch _ {
            completion(false)
        }
    }
    
   class func info(forUserID: String, completion: @escaping (User) -> Swift.Void) {
        Database.database().reference().child("users").child(forUserID).child("credentials").observeSingleEvent(of: .value, with: { (snapshot) in
            if let data = snapshot.value as? [String: String] {
                let name = data["name"]!
                 var nickName = "Anonimo"
                 if let nk =  data["nickName"] {
                    nickName = nk
                }
               
                let email = data["email"]!
                let link = URL.init(string: data["profilePicLink"]!)
                URLSession.shared.dataTask(with: link!, completionHandler: { (data, response, error) in
                    if error == nil {
                        let profilePic = UIImage.init(data: data!)
                        let user = User.init(name: name, email: email, id: forUserID, profilePic: profilePic!,nickName: nickName)
                        completion(user)
                    }
                }).resume()
                
            }
        })
    }

    
    
    class func blockUser(user: User, completion: @escaping (Bool) -> Swift.Void) {
        
        if let currentUserID = Auth.auth().currentUser?.uid {
            
            Database.database().reference().child("users").child(currentUserID).child("usersBlock").child(user.id).setValue(true, withCompletionBlock: { (errr, _) in
                if errr == nil {
                    completion(true)
                }
            })
            
        }
    }
    
    class func desblockUser(user: User, completion: @escaping (Bool) -> Swift.Void) {
        
        if let currentUserID = Auth.auth().currentUser?.uid {
            Database.database().reference().child("users").child(currentUserID).child("usersBlock").child(user.id).setValue(false, withCompletionBlock: { (errr, _) in
                if errr == nil {
                    completion(true)
                }
            })
            
        }
    }
    
    
    class func checkBlockUser(user: User, completion: @escaping (Bool) -> Swift.Void) {
        
        if let currentUserID = Auth.auth().currentUser?.uid {
            Database.database().reference().child("users").child(currentUserID).child("usersBlock").child(user.id).observeSingleEvent(of: .value, with: { (snapshot) in
               
                if snapshot.exists() {
                    
                    let value = snapshot.value as? Bool
                    if(value)!{
                         completion(true)
                        return
                    }else{
                         completion(false)
                    }
                   
                   
                }else{
                     completion(false)
       
                }
                
              
            })
            
        }
        
    }
    
    class func checkBlockUserMy(user: User, completion: @escaping (Bool) -> Swift.Void) {
        
        if let currentUserID = Auth.auth().currentUser?.uid {
            Database.database().reference().child("users").child(user.id).child("usersBlock").child(currentUserID).observeSingleEvent(of: .value, with: { (snapshot) in
                
                if snapshot.exists() {
                    
                    let value = snapshot.value as? Bool
                    if(value)!{
                        completion(true)
                    }else {
                         completion(false)
                    }
                    
                    
                }else{
                    completion(false)
           
                }
               
                
            })
            
        }
        
    }
    
    
    
    class func downloadAllUsers(exceptID: String, completion: @escaping (User) -> Swift.Void) {
        Database.database().reference().child("users").observe(.childAdded, with: { (snapshot) in
            let id = snapshot.key
            let data = snapshot.value as! [String: Any]
            let credentials = data["credentials"] as! [String: String]
            if id != exceptID {
                let name = credentials["name"]!
                var nickName = "Anonimo"
                if let nk =  credentials["nickName"] {
                    nickName = nk
                }
                
                let email = credentials["email"]!
                let link = URL.init(string: credentials["profilePicLink"]!)
                URLSession.shared.dataTask(with: link!, completionHandler: { (data, response, error) in
                    if error == nil {
                        let profilePic = UIImage.init(data: data!)
                        let user = User.init(name: name, email: email, id: id, profilePic: profilePic!, nickName: nickName)
                        completion(user)
                    }
                }).resume()
                
            }
        })
    }
    
    class func checkUserVerification(completion: @escaping (Bool) -> Swift.Void) {
        Auth.auth().currentUser?.reload(completion: { (_) in
            let status = (Auth.auth().currentUser?.isEmailVerified)!
            completion(status)
        })
    }

    
    //MARK: Inits
    init(name: String, email: String, id: String, profilePic: UIImage, nickName: String) {
        self.name = name
        self.email = email
        self.id = id
        self.profilePic = profilePic
        self.nickName = nickName
    }
}

