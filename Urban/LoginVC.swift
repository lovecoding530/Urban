//
//  ViewController.swift
//  Urban
//
//  Created by Kangtle on 8/4/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase

class LoginVC: UIViewController {
    var ref = Database.database().reference()

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    @IBAction func onPressedLogin(_ sender: Any) {
        self.view.endEditing(true)
        let email = emailField.text
        let password = passwordField.text
        if(password == "" || !Helper.isValidEmail(email: email!)){
            Helper.showMessage(target: self, title: "", message: "Please enter email and password correctly")
            return
        }
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Please wait..."
        Auth.auth().signIn(withEmail: email!, password: password!){ (user, error) in
            
            if((error) != nil){
                spinnerActivity.hide(animated: true)
                Helper.showMessage(target: self, title: "", message: (error?.localizedDescription)!)
            }else{
                let userDefault = UserDefaults.standard
                let uid = Auth.auth().currentUser?.uid ?? ""
                
                let trainerRef = self.ref.child("trainers/\(uid)")
                trainerRef.observeSingleEvent(of: .value, with: {(snapshot) in
                    
                    if snapshot.exists() {
                        userDefault.set(true, forKey: "is_trainer")
                        self.performSegue(withIdentifier: "TrainerTab", sender: self)
                    }else{
                        userDefault.set(false, forKey: "is_trainer")
                        if(user?.email == ADMIN_EMAIL){
                            let nav = STORYBOARD.instantiateViewController(withIdentifier: "AdminNav") as! UINavigationController
                            APPDELEGATE.window?.rootViewController = nav
                        }else{
                            self.performSegue(withIdentifier: "LoginToMain", sender: self)
                        }
                    }
                    
                    spinnerActivity.hide(animated: true)
                })
            }
        }
    }
}

