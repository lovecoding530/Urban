//
//  VideosGroupOfGymTableViewCell.swift
//  Urban
//
//  Created by Kangtle on 9/19/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import GoogleMaps

class VideosGroupOfGymTableViewCell: UITableViewCell,
                                     UICollectionViewDelegate, UICollectionViewDataSource
{

    @IBOutlet weak var gymNameLabel: UILabel!
    @IBOutlet weak var gymAddressLabel: UILabel!
    @IBOutlet weak var videosCollectionView: UICollectionView!
    @IBOutlet weak var gymButton: UIButton!
    @IBOutlet weak var mapView: GMSMapView!
    
    var workouts: [Workout]! = nil
    var videos: [[String: Any]]! = nil

    let ref = Database.database().reference()
    let storageRef = Storage.storage().reference()
    var isAllVideos = false

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setWorkouts(workouts: [Workout]) {
        isAllVideos = false
        self.workouts = workouts
        videosCollectionView.delegate = self
        videosCollectionView.dataSource = self
        self.videosCollectionView.reloadData()
    }
    
    func setVideos(videos: [[String: Any]]){
        isAllVideos = true
        self.videos = videos
        videosCollectionView.delegate = self
        videosCollectionView.dataSource = self
        self.videosCollectionView.reloadData()
    }
    
    func getSetsCount() -> Int{
        var count = 0
        for workout in self.workouts {
            count = count + workout.sets.count
        }
        return count
    }
    
    func getWorkoutIndex(indexPath: IndexPath) -> Int{
        var tempIndex = indexPath.row
        var workoutIndex = 0
        for workout in self.workouts {
            tempIndex = tempIndex - workout.sets.count
            if tempIndex >= 0 {
                workoutIndex = workoutIndex + 1
            }else{
                break
            }
        }
        return workoutIndex
    }
    
    func getSetIndex(indexPath: IndexPath) -> Int {
        var tempIndex = indexPath.row
        for workout in self.workouts {
            let temp = tempIndex - workout.sets.count
            if temp < 0{
                break
            }else{
                tempIndex = temp
            }
        }
        return tempIndex
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isAllVideos {
            return self.videos.count
        }else{
            return getSetsCount()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideosForGym", for: indexPath) as! WorkoutCollectionCell
        
        if isAllVideos {
            
            let video = videos[indexPath.row]
            let videoName = video["video_name"] as! String
            let videoThumbUrl = video["thumb_url"] as! String
            
            
            cell.workoutNameLabel.text = videoName
            if cell.gradientLayer == nil {
                cell.gradientLayer = Helper.insertGradientLayer(target: cell.workoutImageView)
            }
            let reference = storageRef.child(videoThumbUrl)
            let placeholderImage = UIImage(named: "placeholder_fitness.png")
            cell.workoutImageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
        }else{
            let workout = self.workouts[getWorkoutIndex(indexPath: indexPath)]
            
            cell.workoutNameLabel.text = workout.name
            if cell.gradientLayer == nil {
                cell.gradientLayer = Helper.insertGradientLayer(target: cell.workoutImageView)
            }
            
            let workoutSet = workout.sets[getSetIndex(indexPath: indexPath)]
            
            let reference = storageRef.child(workoutSet.thumbUrl)
            let placeholderImage = UIImage(named: "placeholder_fitness.png")
            cell.workoutImageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
        }
        return cell
    }
}
