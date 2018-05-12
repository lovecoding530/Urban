//
//  Workout.swift
//  Urban
//
//  Created by Kangtle on 8/14/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import CoreLocation

class Workout {
    
    var id: String!
    var name: String!
    var rating: Int!
    var photoUrl: String!
    var photo: UIImage!
    var trainer: Trainer!
    var gymId: String!
    var gym: Gym!
    var sets: Array<WorkoutSet>!
    var score: Int!
    var numberOfClients: Int!
    var duration: Int!
    var type: String?
    var level: String?
    var description: String?
    var muscleGroup: String?
    var caloriesBurn: Int?
    
    init() {
        
    }
    
    init(withDic: NSDictionary){
        self.name = withDic["name"] as! String
        self.photoUrl = withDic["preview_photo_url"] as! String        

        self.score = withDic["score"] as? Int ?? 0
        self.numberOfClients = withDic["number_of_clients"] as? Int ?? 0
        if numberOfClients == 0 {
            self.rating = 0
        }else{
            self.rating = score/numberOfClients
        }
        self.duration = withDic["duration"] as! Int
        
        self.gymId = withDic["gym_id"] as! String
        self.type = withDic["type"] as? String
        self.level = withDic["level"] as? String
        self.description = withDic["description"] as? String
        self.muscleGroup = withDic["muscle_group"] as? String
        self.caloriesBurn = withDic["calories_burn"] as? Int
        self.sets = [WorkoutSet]()
    }
}
