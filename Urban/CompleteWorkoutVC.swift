//
//  CompleteWorkoutVC.swift
//  Urban
//
//  Created by Kangtle on 8/17/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Cosmos
import Firebase

class CompleteWorkoutVC: UIViewController {

    var workout: Workout! = nil
    var ref: DatabaseReference!

    @IBOutlet weak var caloriesBurnLabel: UILabel!
    @IBOutlet weak var rateView: UIView!
    @IBOutlet weak var trainerImageView: UIImageView!
    @IBOutlet weak var trainerNameLabel: UILabel!
    @IBOutlet weak var ratingControl: CosmosView!
    @IBOutlet weak var alphaView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        ref = Database.database().reference()
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        rateView.isHidden = true
        alphaView.isHidden = true
        caloriesBurnLabel.text = String(workout.caloriesBurn ?? 0)

        trainerImageView.layer.cornerRadius = trainerImageView.frame.width/2
        trainerImageView.clipsToBounds = true

        trainerImageView.image = workout.trainer.photo
        trainerNameLabel.text = "Rate \(workout.trainer.name ?? "") to improve"
        ratingControl.rating = 0
        
        // Do any additional setup after loading the view.
    }
    @IBAction func onPressedRateTrainer(_ sender: Any) {
        rateView.isHidden = false
        alphaView.isHidden = false
    }

    @IBAction func onPressedSubmit(_ sender: Any) {
        let rate = Int(ratingControl.rating)
        let trainerRatingRef = ref.child("trainers/\(workout.trainer.id ?? "")")
        trainerRatingRef.updateChildValues([
            "score" : workout.trainer.score + rate,
            "number_of_clients" : workout.trainer.numberOfClients + 1
        ])

        let workoutRatingRef = ref.child("workouts/\(workout.id ?? "")")
        workoutRatingRef.updateChildValues([
            "score" : workout.score + rate,
            "number_of_clients" : workout.numberOfClients + 1
        ])

        
        let historyRef = ref.child("workout_history/\(Auth.auth().currentUser?.uid ?? "")").childByAutoId()
        
        let duration = workout.duration ?? 0
        let nowTimestamp = Int64(Date().timeIntervalSince1970)
        let startTimeStamp = nowTimestamp - Int64(duration * 60)
        historyRef.setValue([
            "gym_id" : workout.gym.id ?? "",
            "gym_name" : workout.gym.name ?? "",
            "workout_id" : workout.id ?? "",
            "workout_name" : workout.name ?? "",
            "duration" : workout.duration ?? 0,
            "time" : startTimeStamp
        ])
        
        self.tabBarController?.selectedIndex = 0
        self.tabBarController?.tabBar.isHidden = false

        let rootView = self.navigationController?.viewControllers.first as! FindUrbanGymVC
        rootView.originalView()
        self.navigationController?.popToRootViewController(animated: false)
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
