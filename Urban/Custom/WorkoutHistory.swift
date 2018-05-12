//
//  File.swift
//  Urban
//
//  Created by Kangtle on 8/16/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit

class WorkoutHistory {
    
    var id: String!
    var gym: Gym!
    var gymId: String!
    var workoutId: String!
    var workoutName: String!
    var startTime: Date!
    var endTime: Date!
    var timeStamp: Int64!

    init(withDic: NSDictionary){
        self.gymId = withDic["gym_id"] as! String
        self.workoutId = withDic["workout_id"] as! String
        self.workoutName = withDic["workout_name"] as! String
        
        self.timeStamp = withDic["time"] as! Int64
        let duration = withDic["duration"] as! Int
        
        self.startTime = Date.init(timeIntervalSince1970: TimeInterval(self.timeStamp))
        self.endTime = Date.init(timeIntervalSince1970: TimeInterval(self.timeStamp+Int64(duration*60)))
    }
    
}
