//
//  User.swift
//  Urban
//
//  Created by Kangtle on 8/24/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import CoreLocation

class User {
    
    var id: String!
    var name: String!
    var email: String!
    var photoUrl: String!
    var photo: UIImage!
    var country: String!
    var city: String!
    var referralLink: String!
    var inviteFrom: String!
    var memebershipAt: Int64!
    var memebershipNum: Int!
    var balance: Double!
    
    init(withDic: [String: Any]){
        self.name = withDic["name"] as? String ?? ""
        self.email = withDic["email"]  as? String ?? ""
        self.photoUrl = withDic["photo_url"]  as? String ?? ""
        self.country = withDic["country"]  as? String ?? ""
        self.city = withDic["city"]  as? String ?? ""
        self.referralLink = withDic["referral_link"]  as? String ?? ""
        self.inviteFrom = withDic["invite_from"]  as? String ?? ""
        self.memebershipAt = withDic["membership_at"] as? Int64 ?? 0
        self.memebershipNum = withDic["membership_num"] as? Int ?? 0
        self.balance = withDic["balance"] as? Double ?? 0.0
    }
    
}
