//
//  Feedback.swift
//  Urban
//
//  Created by Kangtle on 9/7/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import CoreLocation

class Feedback {
    var id: String!
    var feedback: String!
    var clientId: String!
    var client: User!
    var time: Date!
    var timestamp: Int64!
    var workoutId: String!
    var workout: Workout!
    
    init(){
    }
    
    init(withDic: [String: Any]){
        self.feedback = withDic["feedback"] as! String
        self.timestamp = withDic["time"] as! Int64
        self.time = Date(timeIntervalSince1970: TimeInterval(timestamp))
        self.clientId = withDic["client_id"] as! String
    }
}
