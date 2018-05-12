//
//  SettingVC.swift
//  Urban
//
//  Created by Kangtle on 8/8/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class SettingVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var ref = Database.database().reference()
    let storageRef = Storage.storage().reference()

    let settingRows = ["Account Settings", "Personal Settings", "Referral Program"]
    
    var userProfile: User!
    var isTrainer = false
    let userDefaults = UserDefaults.standard
    
    let payment = Payment()

    @IBOutlet weak var payButton: UIButton!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userAddressLabel: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true

        userImageView.layer.cornerRadius = userImageView.frame.width/2
        userImageView.clipsToBounds = true
//        getUserProfile()
        isTrainer = userDefaults.bool(forKey: "is_trainer")
        payButton.isHidden = !payment.checkMembership()

    }
    override func viewWillAppear(_ animated: Bool) {
        let currentUser = APPDELEGATE.currenntUser
        self.userImageView.image = currentUser?.photo
        self.userNameLabel.text = currentUser?.name

        if currentUser?.country != "" {
            self.userAddressLabel.text = "\(currentUser?.city ?? ""), \(currentUser?.country ?? "")"
        }
    }
    
    func getUserProfile() {
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Please wait..."
        
        let uid = Auth.auth().currentUser?.uid ?? ""
        let userRef: DatabaseReference
        if isTrainer {
            userRef = ref.child("trainers/\(uid)")
        }else{
            userRef = ref.child("clients/\(uid)")
        }
        
        userRef.observe(.value, with: { (snapshot) in
            let userDic = snapshot.value  as? [String : Any]
            if userDic != nil {
                self.userProfile = User(withDic: userDic!)
                self.userProfile.id = uid
                let reference = self.storageRef.child(self.userProfile.photoUrl)
                let placeholderImage = UIImage(named: "placeholder_user.png")
                self.userImageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
                self.userNameLabel.text = self.userProfile.name
                if self.userProfile.country != "" {
                    self.userAddressLabel.text = "\(self.userProfile.city ?? ""), \(self.userProfile.country ?? "")"
                }
            }
            spinnerActivity.hide(animated: true)
        })
    }
    
    @IBAction func onPressedSignout(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            let signinNC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SigninNC") as! UINavigationController
            APPDELEGATE.window?.rootViewController = signinNC
//            self.present(signinNC, animated: true, completion: nil)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingRows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let title = settingRows[indexPath.row]
        let imageName = title.replacingOccurrences(of: " ", with: "_").lowercased()
        
        cell.imageView?.image = UIImage(named: imageName)
        cell.textLabel?.text = title
        cell.backgroundColor = UIColor.clear
        return cell
    }
    
//    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
//        let cell = tableView.cellForRow(at: indexPath)
//        cell?.backgroundColor = UIColor.init(rgb: 0x2D2E40).withAlphaComponent(0.8)
//        return indexPath
//    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            print("account")
            let accountSettingsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AccountSettings") as! AccountSettingsVC
            accountSettingsVC.user = APPDELEGATE.currenntUser
            self.present(accountSettingsVC, animated: true, completion: nil)
        case 1:
            print("personal")
            if isTrainer {
                let trainerProfileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TrainerProfileVC") as! TrainerProfileVC
                trainerProfileVC.trainerId = APPDELEGATE.currenntUser.id
                self.present(trainerProfileVC, animated: true, completion: nil)
            }else{
                let personalSettingsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PersonalSettings") as! PersonalSettingsVC
                personalSettingsVC.user = APPDELEGATE.currenntUser
                self.present(personalSettingsVC, animated: true, completion: nil)
            }
        case 2:
            print("referral")
            let referralSettingsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ReferralProgram") as! ReferralProgramVC
            referralSettingsVC.user = APPDELEGATE.currenntUser
            self.present(referralSettingsVC, animated: true, completion: nil)
        default: break
        }
    }
    
    @IBAction func onPressedTerms(_ sender: Any) {
    }
    
    @IBAction func onPressedPay(_ sender: Any) {
        payment.payWithPaymentMethod(viewController: self.tabBarController) { (error, isSuccess) in
            if(error == nil && isSuccess == true){
                DispatchQueue.main.async {
                    Helper.showMessage(target: self, title: "", message: "Successfully paid")
                    self.payButton.isHidden = true
                    for index in 0...3 {
                        let item = self.tabBarController?.tabBar.items?[index]
                        item?.isEnabled = true
                    }
                }
            }else{
                Helper.showMessage(target: self, title: "", message: "An error happens, Please try again")
            }
        }
    }
}
