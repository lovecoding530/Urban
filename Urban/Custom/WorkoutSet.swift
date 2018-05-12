//
//  WorkoutSet.swift
//  Urban
//
//  Created by Kangtle on 8/15/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//
import UIKit
import CoreLocation

class WorkoutSet {
    
    var id: String!
    var name: String!
    var description: String!
    var duration: Int!
    var reps: Int!
    var thumbUrl: String!
    var thumb: UIImage!
    var videoUrl: String!

    init(){
    }
    
    init(withDic: NSDictionary){
        self.description = withDic["description"] as! String
        self.duration = withDic["duration"] as! Int
        self.reps = withDic["reps"] as? Int ?? 0
        self.thumbUrl = withDic["thumb_image_url"] as! String
        self.videoUrl = withDic["video_url"] as! String
    }
}
