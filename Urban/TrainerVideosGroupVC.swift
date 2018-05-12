//
//  TrainerVideosGroupVC.swift
//  Urban
//
//  Created by Kangtle on 9/19/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import MobileCoreServices
import GoogleMaps

class TrainerVideosGroupVC: UIViewController,
                            UITableViewDelegate, UITableViewDataSource,
                            UIImagePickerControllerDelegate, UINavigationControllerDelegate,
                            UIGestureRecognizerDelegate
{

    let storageRef = Storage.storage().reference()
    var ref = Database.database().reference()
    var trainerGyms: [Gym] = []
    var videos = [[String: Any]]()
    var imagePicker = UIImagePickerController()

    var indexOfTappedGym = -1
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        imagePicker.delegate = self
        getData()
        // Do any additional setup after loading the view.
    }
    
    
    func getData(){
        let uid = Auth.auth().currentUser?.uid ?? ""
        let trainerGymRef = ref.child("trainer_gyms/\(uid)")
        trainerGymRef.observe(.childAdded, with: {snapshot in
            print("trainerGym", snapshot.key)
            let gymId = snapshot.key
            let gymRef = self.ref.child("gyms/\(gymId)")
            gymRef.observeSingleEvent(of: .value, with: {snapshot in
                guard let gymDic = snapshot.value as? NSDictionary else {return}
                let mGym = Gym(withDic: gymDic)
                self.trainerGyms.append(mGym)
                let trainerWorkoutRef = self.ref.child("workouts").queryOrdered(byChild: "gym_trainer").queryEqual(toValue: "\(gymId)_\(uid)")
                trainerWorkoutRef.observe(.childAdded, with: {snapshot in
                    print("trainerWorkout", snapshot.value ?? "")
                    guard let workoutDic = snapshot.value as? NSDictionary else {return}
                    let mWorkout = Workout(withDic: workoutDic)
                    mGym.workouts.append(mWorkout)
                    
                    let workoutId = snapshot.key
                    //WorkoutSet' thumb is equal video's thumb. so I use WorkoutSet instead of Video.
                    let workoutSetRef = self.ref.child("sets/\(workoutId)")
                    workoutSetRef.observe(.childAdded, with: {snapshot in
                        print("workoutSet", snapshot.value ?? "")
                        guard let workoutSetDic = snapshot.value as? NSDictionary else {return}
                        let mSet = WorkoutSet(withDic: workoutSetDic)
                        mWorkout.sets.append(mSet)
                        self.tableView.reloadData()
                    })
                })
            })
        })
        
        let videoRef = ref.child("videos/\(uid)")
        videoRef.observe(.value, with: {snapshot in
            let videosDic = snapshot.value as? [String: Any] ?? [:]
            self.videos = (Array(videosDic.values) as? [[String: Any]])!
            self.tableView.reloadData()
        })
    }

    // MARK: - TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trainerGyms.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.indexOfTappedGym == indexPath.row {
            return 475.0
        }else{
            return 225.0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideosGroupOfGym", for: indexPath) as! VideosGroupOfGymTableViewCell
        
        if indexPath.row < trainerGyms.count {
            let gym = self.trainerGyms[indexPath.row]
            cell.gymNameLabel.text = gym.name ?? ""
            cell.gymAddressLabel.text = gym.address ?? ""
            cell.setWorkouts(workouts: gym.workouts)
            cell.gymButton.tag = indexPath.row

            if self.indexOfTappedGym == indexPath.row {
                cell.mapView.isHidden = false

                let camera = GMSCameraPosition.camera(withLatitude: (gym.location.latitude),
                                                      longitude: (gym.location.longitude), zoom: 16.0)
                cell.mapView.camera = camera

                let marker = GMSMarker()
                marker.position = gym.location
                marker.icon = UIImage(named: "circle_marker")
                marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
                marker.map = cell.mapView
            }else{
                cell.mapView.isHidden = true
            }
        }else{
            cell.gymNameLabel.text = "All Videos"
            cell.gymAddressLabel.text = "My all videos"
            cell.setVideos(videos: self.videos)
            cell.gymButton.tag = indexPath.row
            cell.mapView.isHidden = true
        }
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressedVideo(_:)))
        cell.videosCollectionView.addGestureRecognizer(lpgr)
        return cell
    }
    
    @IBAction func onTappedGym(_ sender: UIButton) {
        if self.indexOfTappedGym == sender.tag {
            self.indexOfTappedGym = -1
        }else{
            self.indexOfTappedGym = sender.tag
        }
        if(indexOfTappedGym < self.trainerGyms.count){
            self.tableView.reloadData()
        }
    }
    
    @IBAction func onPressedAdd(_ sender: Any) {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .photoLibrary
            self.imagePicker.mediaTypes = [String(kUTTypeMovie)]
            self.present(self.imagePicker, animated: true, completion: nil)
        #else
            if(UIImagePickerController.isSourceTypeAvailable(.camera)){
                self.imagePicker.allowsEditing = false
                self.imagePicker.sourceType = .camera
                //            self.imagePicker.cameraCaptureMode = .video
                self.imagePicker.mediaTypes = [String(kUTTypeMovie)]
                self.present(self.imagePicker, animated: true, completion: nil)
            }else{
                Helper.showMessage(target: self, title: "", message: "This device is no camera")
            }
        #endif
    }
    
    @IBAction func onLongPressedVideo(_ sender: UILongPressGestureRecognizer) {
        if sender.state != .began {
            return
        }

        let tableViewPoint = sender.location(in: self.tableView)
        let selectedTableCell = tableView.cellForRow(at: tableView.indexPathForRow(at: tableViewPoint)!) as! VideosGroupOfGymTableViewCell

        let collectionPoint = sender.location(in: selectedTableCell.videosCollectionView)
        let indexPath = selectedTableCell.videosCollectionView.indexPathForItem(at: collectionPoint)
        if indexPath == nil {
            return
        }
        let optionMenu = UIAlertController(title: nil, message: "Delete selected video", preferredStyle: .actionSheet)
        
        // 2
        let deleteAction = UIAlertAction(title: "Delete Video", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            let alert = UIAlertController(title: "URBAN", message: "Are you sure to delete this video?", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
            {
                (result : UIAlertAction) -> Void in
                var videoUrl = ""
                if selectedTableCell.isAllVideos {
                    let video = self.videos[(indexPath?.row)!]
                    videoUrl = video["video_url"] as! String
                }else{
                    let workout = selectedTableCell.workouts[selectedTableCell.getWorkoutIndex(indexPath: indexPath!)]
                    let workoutSet = workout.sets[selectedTableCell.getSetIndex(indexPath: indexPath!)]
                    videoUrl = workoutSet.videoUrl
                }
                let videoRef = self.ref.child("videos/\(Auth.auth().currentUser?.uid ?? "")")
                let deleteRef = videoRef.queryOrdered(byChild: "video_url").queryEqual(toValue: videoUrl)
                deleteRef.observe(.childAdded, with: { snapshot in
                    videoRef.child(snapshot.key).removeValue()
                })

            }
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default)
            {
                (result : UIAlertAction) -> Void in
            }
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)

        })
        
        //
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        
        
        // 4
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        
        // 5
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: false, completion: nil)
        
        if let url = info[UIImagePickerControllerMediaURL] as? URL {
            let videoEditVC = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "VideoEditVC") as! VideoEditVC
            videoEditVC.videoUrl = url
            self.present(videoEditVC, animated: true, completion: nil)
            return
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
