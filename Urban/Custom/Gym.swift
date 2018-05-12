//
//  Gym.swift
//  Urban
//
//  Created by Kangtle on 8/11/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import CoreLocation

class Gym {
        
    var id: String!
    var name: String!
    var address: String!
    var location: CLLocationCoordinate2D!
    var thumb: UIImage!
    var photo: UIImage!
    var photoUrl: String!
    var workouts: [Workout]!
    
    init(withDic: NSDictionary){
        self.name = withDic["name"] as! String
        self.address = withDic["address"] as! String
        self.photoUrl = withDic["photo_url"] as! String

        let _location = withDic["location"] as! NSDictionary
        let latitude = _location["lat"] as! Double
        let longitude = _location["long"] as! Double
        self.location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        workouts = [Workout]()
    }
    
    func distanceFromMe(distanceUnit: String) -> Double {
        return Helper.distance(
            fromLat: location.latitude,
            fromLong: location.longitude,
            distanceUnit: distanceUnit)
    }
}
