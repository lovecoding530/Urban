//
//  StartSetVC.swift
//  Urban
//
//  Created by Kangtle on 8/15/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Firebase
import FirebaseStorage

class StartSetVC: UIViewController {

    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var setNameLabel: UILabel!
    @IBOutlet weak var setDescriptionLabel: UILabel!
    @IBOutlet weak var setDurationLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var muscleGroupLabel: UILabel!
    @IBOutlet weak var caloriesBurnLabel: UILabel!
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var setRepsLabel: UILabel!

    var player: AVPlayer?
    var avpController = AVPlayerViewController()
    var workout: Workout! = nil
    var currentSet: Int!

    let storageRef = Storage.storage().reference()
    var dbRef = Database.database().reference()

    var isView: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        self.avpController = AVPlayerViewController()
        avpController.view.frame = videoView.frame
        self.addChildViewController(avpController)
        self.view.addSubview(avpController.view)
        // Do any additional setup after loading the view.
        typeLabel.text = workout.type ?? ""
        levelLabel.text = workout.level ?? ""
        muscleGroupLabel.text = workout.muscleGroup
        caloriesBurnLabel.text = "\(workout.caloriesBurn ?? 0) kcal"
        setupSet()
        
        if isView {
            startBtn.setTitle("INAPPROPRIATE CONTENT", for: .normal)
        }
    }

    func setupSet(){
        let set = workout.sets[currentSet]
        setNameLabel.text = set.name
        setDescriptionLabel.text = set.description
        setDurationLabel.text = "\(String(set.duration)) min"
        if set.reps > 0 {
            setRepsLabel.text = "\(set.reps ?? 0)"
        }
        
        storageRef.child(set.videoUrl).downloadURL(){  url, error in
            if error == nil {
                let player = AVPlayer(url: url!)
                self.avpController.player = player
            }
        }
    }
    
    @IBAction func onBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func onPressedStartSet(_ sender: Any) {
        if isView {
            let alert = UIAlertController(title: "URBAN", message: "Are you sure it is inappropriate content?", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default)
            {
                (result : UIAlertAction) -> Void in
                
                let workoutId = self.workout.id ?? ""
                let setId = self.workout.sets[self.currentSet].id ?? ""
                
                let inappropriateRef = self.dbRef.child("inappropriate_contents").childByAutoId()
                inappropriateRef.setValue(
                    [
                        "workout_id" : workoutId,
                        "set_id" : setId
                    ]
                )
            }
            let cancelAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default)
            
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }else{
            let doingSetVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DoingSetVC") as! DoingSetVC
            doingSetVC.set = workout.sets[currentSet]
            doingSetVC.onDoneBlock = {isDoneSet in
                if isDoneSet {
                    self.currentSet = self.currentSet + 1
                    if(self.currentSet >= self.workout.sets.count){
                        self.performSegue(withIdentifier: "CompleteWorkoutVC", sender: self)
                    }else{
                        self.setupSet()
                    }
                }
            }
            self.present(doingSetVC, animated: true)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if(segue.identifier == "CompleteWorkoutVC"){
            let completeWorkoutVC = segue.destination as! CompleteWorkoutVC
            completeWorkoutVC.workout = workout
        }
    }
}
