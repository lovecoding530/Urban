//
//  AccountSettingsVC.swift
//  Urban
//
//  Created by Kangtle on 8/24/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase

class AccountSettingsVC: UIViewController {
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var emailEdit: UITextField!
    @IBOutlet weak var oldPasswordEdit: UITextField!
    @IBOutlet weak var newPasswordEdit: UITextField!
    @IBOutlet weak var confirmPasswordEdit: UITextField!

    var user: User!

    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toolBar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        
        emailEdit.text = user.email
        // Do any additional setup after loading the view.
    }

    @IBAction func onBack(_ sender: Any) {
        self.performSegueToReturnBack()
    }

    @IBAction func onPressedChangePassword(_ sender: Any) {
        let oldPassword = oldPasswordEdit.text
        let newPassword = newPasswordEdit.text
        let confirmPassword = confirmPasswordEdit.text
        
        if (oldPassword == "") {
            Helper.showMessage(target: self, title: "", message: "Please enter correctly"){
                self.oldPasswordEdit.becomeFirstResponder()
            }
            return
        }
        if (newPassword == "") {
            Helper.showMessage(target: self, title: "", message: "Please enter correctly"){
                self.newPasswordEdit.becomeFirstResponder()
            }
            return
        }
        if (confirmPassword == "") {
            Helper.showMessage(target: self, title: "", message: "Please enter correctly"){
                self.confirmPasswordEdit.becomeFirstResponder()
            }
            return
        }
        if (newPassword != confirmPassword){
            Helper.showMessage(target: self, title: "", message: "Please enter correctly"){
                self.newPasswordEdit.becomeFirstResponder()
            }
            return
        }
        let email = Auth.auth().currentUser?.email ?? ""
        let credentials = EmailAuthProvider.credential(withEmail: email, password: oldPassword!)
        
        Auth.auth().currentUser?.reauthenticate(with: credentials, completion: { (error) in
            if error != nil{
                Helper.showMessage(target: self, title: "", message: (error?.localizedDescription)!)
            }else{
                Auth.auth().currentUser?.updatePassword(to: newPassword!, completion: {(error) in
                    if error != nil{
                        Helper.showMessage(target: self, title: "", message: (error?.localizedDescription)!)
                    }else{
                        Helper.showMessage(target: self, title: "", message: "Updated successfully")
                    }
                })
            }
        })
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
