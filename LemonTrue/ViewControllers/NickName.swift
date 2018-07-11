//
//  NickName.swift
//  LemonTrue
//
//  Created by Guilherme Pereira Neto on 11/07/2018.
//  Copyright © 2018 Guilherme Pereira Neto. All rights reserved.
//

import UIKit
import Firebase

class NickName: UIViewController{
    
    @IBOutlet weak var imgProfile: RoundedImageView!
    
    @IBOutlet weak var tfNickname: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let currentUserID = Auth.auth().currentUser?.photoURL?.absoluteString {
            
            let url = URL(string: currentUserID)
            let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
            imgProfile.image = UIImage(data: data!)
            
        }
        
       
    
    }
    
    @IBAction func btContinuar(_ sender: RoundedButton) {
        
        if let currentUserID = Auth.auth().currentUser?.uid {
            
            Database.database().reference().child("users").child(currentUserID)
                .child("credentials").child("nickName").setValue(tfNickname.text, withCompletionBlock:  { (errr, _) in
                    if errr == nil {
                        self.pushTomainView()
                    }
                })
            
        }
        
        
      
    }
    
    
    func pushTomainView() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "Navigation") as! NavVC
        self.show(vc, sender: nil)
    }
}
