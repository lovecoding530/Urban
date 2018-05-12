//
//  ResetPasswordVC.swift
//  Urban
//
//  Created by Kangtle on 8/7/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase

class ResetPasswordVC: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func onPressReset(_ sender: Any) {
        let email = emailTextField.text
        if(!Helper.isValidEmail(email: email!)){
            Helper.showMessage(target: self, title: "", message: "Please enter email correctly")
            return
        }
        
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Please wait..."
        
        Auth.auth().sendPasswordReset(withEmail: email!) { (error) in
            spinnerActivity.hide(animated: true)
            if(error == nil){
                Helper.showMessage(target: self, title: "", message: "We have sent an email for reset password"){
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }else{
                Helper.showMessage(target: self, title: "", message: (error?.localizedDescription)!)
            }
        }
    }
    @IBAction func onBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
