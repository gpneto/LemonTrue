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


import UIKit
import Photos

import Firebase
import FacebookLogin
import FBSDKLoginKit


class WelcomeVC: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    //MARK: Properties
    @IBOutlet weak var darkView: UIView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet var registerView: UIView!
    @IBOutlet var loginView: UIView!
    @IBOutlet weak var profilePicView: RoundedImageView!
    @IBOutlet weak var registerNameField: UITextField!
    @IBOutlet weak var registerEmailField: UITextField!
    @IBOutlet weak var registerPasswordField: UITextField!
    @IBOutlet var waringLabels: [UILabel]!
    @IBOutlet weak var loginEmailField: UITextField!
    @IBOutlet weak var loginPasswordField: UITextField!
    @IBOutlet weak var cloudsView: UIImageView!
    @IBOutlet weak var cloudsViewLeading: NSLayoutConstraint!
    @IBOutlet var inputFields: [UITextField]!
    var loginViewTopConstraint: NSLayoutConstraint!
    var registerTopConstraint: NSLayoutConstraint!
    let imagePicker = UIImagePickerController()
    var isLoginViewVisible = true
    
    @IBOutlet weak var btFBLogin: UIButton!
    var dict : [String : AnyObject]!
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return UIInterfaceOrientationMask.portrait
        }
    }
    
    //MARK: Methods
    func customization()  {
    }
    
 
   
    func cloundsAnimation() {
        let distance = self.view.bounds.width - self.cloudsView.bounds.width
        self.cloudsViewLeading.constant = distance
        UIView.animate(withDuration: 15, delay: 0, options: [.repeat, .curveLinear], animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func showLoading(state: Bool)  {
        if state {
            self.darkView.isHidden = false
            self.spinner.startAnimating()
            UIView.animate(withDuration: 0.3, animations: { 
                self.darkView.alpha = 0.5
            })
            self.btFBLogin.isHidden = true
        } else {
            UIView.animate(withDuration: 0.3, animations: { 
                self.darkView.alpha = 0
            }, completion: { _ in
                self.spinner.stopAnimating()
                self.darkView.isHidden = true
                self.btFBLogin.isHidden = false
            })
        }
    }
    
    func pushToNickName() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "NickName") as! NickName
        self.show(vc, sender: nil)
    }
    
    func pushTomainView() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "Navigation") as! NavVC
        self.show(vc, sender: nil)
    }
    
    func openPhotoPickerWith(source: PhotoSource) {
        switch source {
        case .camera:
            let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
            if (status == .authorized || status == .notDetermined) {
                self.imagePicker.sourceType = .camera
                self.imagePicker.allowsEditing = true
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        case .library:
            let status = PHPhotoLibrary.authorizationStatus()
            if (status == .authorized || status == .notDetermined) {
                self.imagePicker.sourceType = .savedPhotosAlbum
                self.imagePicker.allowsEditing = true
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func switchViews(_ sender: UIButton) {
        if self.isLoginViewVisible {
            self.isLoginViewVisible = false
            sender.setTitle("Login", for: .normal)
            self.loginViewTopConstraint.constant = 1000
            self.registerTopConstraint.constant = 60
        } else {
            self.isLoginViewVisible = true
            sender.setTitle("Create New Account", for: .normal)
            self.loginViewTopConstraint.constant = 60
            self.registerTopConstraint.constant = 1000
        }
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        })
        for item in self.waringLabels {
            item.isHidden = true
        }
    }
    
    @IBAction func register(_ sender: Any) {
        for item in self.inputFields {
            item.resignFirstResponder()
        }
        self.showLoading(state: true)
        User.registerUser(withName: self.registerNameField.text!, email: self.registerEmailField.text!, password: self.registerPasswordField.text!, profilePic: self.profilePicView.image!) { [weak weakSelf = self] (status) in
            DispatchQueue.main.async {
                weakSelf?.showLoading(state: false)
                for item in self.inputFields {
                    item.text = ""
                }
                if status == true {
                    weakSelf?.pushTomainView()
                    weakSelf?.profilePicView.image = UIImage.init(named: "profile pic")
                } else {
                    for item in (weakSelf?.waringLabels)! {
                        item.isHidden = false
                    }
                }
            }
        }
    }
    
    @IBAction func login(_ sender: Any) {
        for item in self.inputFields {
            item.resignFirstResponder()
        }
        self.showLoading(state: true)
        User.loginUser(withEmail: self.loginEmailField.text!, password: self.loginPasswordField.text!) { [weak weakSelf = self](status) in
            DispatchQueue.main.async {
                weakSelf?.showLoading(state: false)
                for item in self.inputFields {
                    item.text = ""
                }
                if status == true {
                    weakSelf?.pushTomainView()
                } else {
                    for item in (weakSelf?.waringLabels)! {
                        item.isHidden = false
                    }
                }
                weakSelf = nil
            }
        }
    }

    
    @IBAction func facebookLogin(_ sender: Any) {
        let fbLoginManager = FBSDKLoginManager()
        self.showLoading(state: true)
        fbLoginManager.logIn(withReadPermissions: ["public_profile", "email"], from: self) { (result, error) in
            if let error = error {
                print("Failed to login: \(error.localizedDescription)")
                 self.showLoading(state: false)
                return
            }
            
            guard let accessToken = FBSDKAccessToken.current() else {
                print("Failed to get access token")
                 self.showLoading(state: false)
                return
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
            
            self.showLoading(state: true)
            User.loginUser(credential: credential) { [weak weakSelf = self](status) in
                DispatchQueue.main.async {
                    weakSelf?.showLoading(state: false)
                    if status == true {
                        weakSelf?.pushToNickName()
                    } else {
                        for item in (weakSelf?.waringLabels)! {
                            item.isHidden = false
                        }
                    }
                    weakSelf = nil
                }
            }
       
            
        }
    }
    
    
    @IBAction func selectPic(_ sender: Any) {
        let sheet = UIAlertController(title: nil, message: "Select the source", preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openPhotoPickerWith(source: .camera)
        })
        let photoAction = UIAlertAction(title: "Gallery", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openPhotoPickerWith(source: .library)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        sheet.addAction(cameraAction)
        sheet.addAction(photoAction)
        sheet.addAction(cancelAction)
        self.present(sheet, animated: true, completion: nil)
    }
    
    //MARK: Delegates
    func textFieldDidBeginEditing(_ textField: UITextField) {
        for item in self.waringLabels {
            item.isHidden = true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.profilePicView.image = pickedImage
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    //MARK: Viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.customization()
    
    }

    
   
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.cloundsAnimation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.cloudsViewLeading.constant = 0
        self.cloudsView.layer.removeAllAnimations()
        self.view.layoutIfNeeded()
    }
}

