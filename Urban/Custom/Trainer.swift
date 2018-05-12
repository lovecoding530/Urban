//
//  Trainer.swift
//  Urban
//
//  Created by Kangtle on 8/12/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import CoreLocation

class Trainer {
    
    var id: String!
    var name: String!
    var email: String!
    var rating: Int!
    var fitnessQualification: String!
    var photoUrl: String!
    var photo: UIImage!
    var score: Int!
    var numberOfClients: Int!

    var title: String!
    var country: String!
    var city: String!
    var overview: String!
    var areas: String!
    var professional: String!

    init(withDic: NSDictionary){
        self.name = withDic["name"] as! String
        self.email = withDic["email"] as! String
        self.fitnessQualification = withDic["fitness_qualification"] as! String
        self.photoUrl = withDic["photo_url"] as? String ?? ""
        
        self.score = withDic["score"] as? Int ?? 0
        self.numberOfClients = withDic["number_of_clients"] as? Int ?? 0
        
        if numberOfClients == 0 {
            self.rating = 0
        }else{
            self.rating = score/numberOfClients
        }
        
        self.title = withDic["title"] as? String ?? ""
        self.country = withDic["country"]  as? String ?? ""
        self.city = withDic["city"]  as? String ?? ""
        self.overview = withDic["overview"] as? String ?? ""
        self.areas = withDic["areas"] as? String ?? ""
        self.professional = withDic["professional"] as? String ?? ""
        
    }
    
}
