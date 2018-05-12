//
//  Opponent.swift
//  Urban
//
//  Created by Kangtle on 8/18/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit

class Opponent {
    
    var id: String!
    var name: String!
    var photoUrl: String!
    var photo: UIImage!
    
    init(id: String, name: String, photoUrl: String, photo: UIImage) {
        self.id = id
        self.name = name
        self.photoUrl = photoUrl
        self.photo = photo
    }
    
    init(withDic: [String : Any]){
        self.name = withDic["name"] as! String
        self.photoUrl = withDic["photo_url"] as? String ?? ""
    }
    
}
