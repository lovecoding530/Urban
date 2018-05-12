//
//  Payment.swift
//  Urban
//
//  Created by Kangtle on 11/3/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import Braintree
import BraintreeDropIn

let toKinizationKey = "sandbox_4gb3fw9v_w492nkrqcq8bzyhq"
let MONTHLY_PAY = 9.99
let MONTH:Int64 = 30 * 24 * 3600

class Payment: Any {
    var ref = Database.database().reference()
    let storageRef = Storage.storage().reference()
    let userDefaults = UserDefaults.standard
    
    func checkMembership() -> Bool{
        let lastMembershipAt = APPDELEGATE.currenntUser.memebershipAt
        let currentTime = Int64(Date().timeIntervalSince1970)
        
        if Int64(currentTime - lastMembershipAt!) > MONTH {
            if APPDELEGATE.currenntUser.balance >= MONTHLY_PAY {
                updateMembershipStatus(isFromBalance: true)
            }else{
                return true
            }
        }
        return false
    }
    
    func updateMembershipStatus(isFromBalance: Bool){
        if(APPDELEGATE.currenntUser.memebershipNum == 1 && !APPDELEGATE.currenntUser.inviteFrom.isEmpty){
            let trainerRef = self.ref.child("trainers/\(APPDELEGATE.currenntUser.inviteFrom ?? "")")
            trainerRef.observeSingleEvent(of: .value, with: {(snapshot) in
                var inviteUserBalanceRef: DatabaseReference!
                if snapshot.exists() {
                    inviteUserBalanceRef = self.ref.child("trainers")
                }else{
                    inviteUserBalanceRef = self.ref.child("clients")
                }
                inviteUserBalanceRef = inviteUserBalanceRef.child(APPDELEGATE.currenntUser.inviteFrom ?? "").child("balance")
                inviteUserBalanceRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    let balance = snapshot.value as? Double ?? 0.0
                    inviteUserBalanceRef.setValue(balance + MONTHLY_PAY)
                })
            })
        }
        
        let restBalance: Double
        if isFromBalance {
            restBalance = APPDELEGATE.currenntUser.balance - 9.99
        }else{
            restBalance = APPDELEGATE.currenntUser.balance
        }
        
        let isTrainer = userDefaults.bool(forKey: "is_trainer")
        let uid = Auth.auth().currentUser?.uid ?? ""
        let userRef: DatabaseReference
        if isTrainer {
            userRef = ref.child("trainers/\(uid)")
        }else{
            userRef = ref.child("clients/\(uid)")
        }
        
        let stateDic: [String: Any] = [
            "balance": restBalance,
            "membership_at": Int64(Date().timeIntervalSince1970),
            "membership_num": APPDELEGATE.currenntUser.memebershipNum + 1
        ]
        
        userRef.updateChildValues(stateDic)
        
    }
    
    func payWithPaymentMethod(viewController: UIViewController!, callback: ((Error?, Bool)->Void)!) {
        
        //NEW
        let request =  BTDropInRequest()
        
        let dropIn = BTDropInController(authorization: toKinizationKey, request: request)
        { (controller, result, error) in
            if (error != nil) {
                print("ERROR")
                callback(error!, false)
            } else if (result?.isCancelled == true) {
                print("CANCELLED")
            } else if let result = result {
                // Use the BTDropInResult properties to update your UI
                // result.paymentOptionType
                // result.paymentMethod
                // result.paymentIcon
                // result.paymentDescription
                if let nonce = result.paymentMethod?.nonce {
                    self.sendRequestPaymentToServer(nonce: nonce, amount: MONTHLY_PAY, callback: callback)
                }
            }
            controller.dismiss(animated: true, completion: nil)
        }
        viewController.present(dropIn!, animated: true, completion: nil)
        
    }
    
    func sendRequestPaymentToServer(nonce: String, amount: Double, callback: ((Error?, Bool)->Void)!) {
        let paymentURL = URL(string: "https://us-central1-uuban-5f08f.cloudfunctions.net/pay")!
        var request = URLRequest(url: paymentURL)
        request.httpBody = "payment_method_nonce=\(nonce)&amount=\(amount)".data(using: String.Encoding.utf8)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) {(data, response, error) -> Void in
            guard let data = data else {
                print(error!.localizedDescription)
                callback(error!, false)
                return
            }
            
            guard let result = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let success = result?["success"] as? Bool, success == true else {
                print("Transaction failed. Please try again.")
                callback(nil, false)
                return
            }
            
            print("Successfully charged. Thanks So Much :)")
            self.updateMembershipStatus(isFromBalance: false)
            
            callback(nil, true)
        }.resume()
    }
}
