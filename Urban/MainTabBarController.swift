//
//  MainTabBarController.swift
//  Urban
//
//  Created by Kangtle on 8/7/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import Braintree
import BraintreeDropIn

class MainTabBarController: UITabBarController {
    var ref = Database.database().reference()
    let storageRef = Storage.storage().reference()
    let userDefaults = UserDefaults.standard
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        let isTrainer = defaults.bool(forKey: "is_trainer")
        
        
        selectedIndex = 2
        let workoutItem = tabBar.items?[0]
        let messageItem = tabBar.items?[1]
        let middleItem = tabBar.items?[2]
        let resultItem = tabBar.items?[3]
        let settingItem = tabBar.items?[4]
        
        //        self.tabBar.tintColor = UIColor.init(red: 245/255, green: 81/255, blue: 95/255, alpha: 1)
        self.tabBar.tintColor = UIColor.init(rgb: 0xFF6666)
        workoutItem?.title = "WORKOUTS"
        workoutItem?.image = UIImage(named: "tab_workout_normal")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        workoutItem?.selectedImage = UIImage(named: "tab_workout_selected")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        
        messageItem?.title = "MESSAGES"
        messageItem?.image = UIImage(named: "tab_message_normal")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        messageItem?.selectedImage = UIImage(named: "tab_message_selected")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        
        if isTrainer {
            middleItem?.title = nil
            middleItem?.image = UIImage(named: "tab_video_normal")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
            middleItem?.selectedImage = UIImage(named: "tab_video_selected")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        }else{
            middleItem?.title = nil
            middleItem?.image = UIImage(named: "tab_map_normal")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
            middleItem?.selectedImage = UIImage(named: "tab_map_selected")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        }
        
        if isTrainer {
            resultItem?.title = "MY GYMS"
        }else{
            resultItem?.title = "RESULTS"
        }
        resultItem?.image = UIImage(named: "tab_result_normal")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        resultItem?.selectedImage = UIImage(named: "tab_result_selected")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        
        settingItem?.title = "SETTINGS"
        settingItem?.image = UIImage(named: "tab_setting_normal")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        settingItem?.selectedImage = UIImage(named: "tab_setting_selected")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        
        self.getUserProfile()
    }
    
    func getUserProfile() {
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Please wait..."
        
        let isTrainer = userDefaults.bool(forKey: "is_trainer")
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
                let currenntUser = User(withDic: userDic!)
                currenntUser.id = uid
                
                let photoRef = self.storageRef.child(currenntUser.photoUrl)
                let placeholderUser = UIImage(named: "placeholder_user")
                let tempImageView = UIImageView()
                tempImageView.sd_setImage(with: photoRef, placeholderImage: placeholderUser){(photo, error, _, _) in
                    currenntUser.photo = tempImageView.image
                    APPDELEGATE.currenntUser = currenntUser
                    spinnerActivity.hide(animated: true)
                    let payment = Payment()
                    if(payment.checkMembership()){
                        for index in 0...3 {
                            let item = self.tabBar.items?[index]
                            item?.isEnabled = false
                        }
                        self.selectedIndex = 4
                    }
                }
            }
        })
    }
}
