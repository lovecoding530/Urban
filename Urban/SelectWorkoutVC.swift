//
//  SelectWorkoutVC.swift
//  Urban
//
//  Created by Kangtle on 8/13/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage


class SelectWorkoutVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var workoutImageView: UIImageView!
    @IBOutlet weak var sortView: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var workoutNameLabel: UILabel!
    @IBOutlet weak var trainerImageView: UIImageView!
    @IBOutlet weak var trainerNameLabel: UILabel!
    @IBOutlet weak var ratingView: UIView!
    @IBOutlet weak var workoutCollectionView: UICollectionView!
    
    let ref = Database.database().reference()
    let storageRef = Storage.storage().reference()
    var gym: Gym! = nil
    var trainer: Trainer! = nil
    var workouts: Array<Workout> = Array()
    var selectedWorkout: Workout! = nil {
        didSet {
            var reference = storageRef.child(selectedWorkout.photoUrl)

            self.workoutImageView.sd_setImage(with: reference, placeholderImage:  UIImage(named: "placeholder_fitness.png"))

            self.workoutNameLabel.text = selectedWorkout.name
//            self.trainerImageView.image = selectedWorkout.trainer.photo
            self.trainerNameLabel.text = selectedWorkout.trainer.name
            self.workoutRating = selectedWorkout.rating
            
            reference = storageRef.child(selectedWorkout.trainer.photoUrl)
            self.trainerImageView.sd_setImage(with: reference, placeholderImage:  UIImage(named: "placeholder_user.png"))
        }
    }
    
    var workoutRating: Int? = nil {
        didSet {
            let ratingStars = ratingView.subviews
            let emptyStarsCount = 5 - workoutRating!
            for index in 0...4 {
                let ratingStar = ratingStars[index]
                if index < emptyStarsCount {
                    ratingStar.isHidden = true
                }else{
                    ratingStar.isHidden = false
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
//        self.navigationItem.title = "\(gym.name.uppercased())'S WORKOUTS"

        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: (self.navigationController?.view.bounds.size.width)!-100, height: 44))
        titleLabel.text = "\(gym.name.uppercased())'S WORKOUTS"
        titleLabel.font = UIFont(name: "Helvetica", size: 16)
        titleLabel.minimumScaleFactor = 0.5
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.center.y = 22
        self.navigationItem.titleView = titleLabel

        
        _ = Helper.insertGradientLayer(target: workoutImageView)
        self.workoutRating = 0
        
        trainerImageView.layer.cornerRadius = trainerImageView.frame.width/2
        trainerImageView.clipsToBounds = true

        self.workoutCollectionView.delegate = self
        self.workoutCollectionView.dataSource = self

        // Do any additional setup after loading the view.
        getWorkouts()
    }

    func getWorkouts(){
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Please wait..."

        var workoutRef: DatabaseQuery
        if(self.trainer == nil){
            workoutRef = self.ref.child("workouts").queryOrdered(byChild: "gym_id").queryEqual(toValue: gym.id)
        }else{
            workoutRef = self.ref.child("workouts").queryOrdered(byChild: "gym_trainer").queryEqual(toValue: "\(gym.id!)_\(trainer.id!)")
        }
        
        workoutRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let _workouts = snapshot.value as? NSDictionary {
                let group = DispatchGroup()
                for (_key, _workout) in _workouts {
                    let mWorkout = Workout(withDic: _workout as! NSDictionary)
                    mWorkout.id = _key as! String
                    
                    self.workouts.append(mWorkout)
                    
                    group.enter()
                    let trainerId = (_workout as! NSDictionary)["trainer_id"] as! String
                    self.ref.child("trainers/\(trainerId)").observeSingleEvent(of: .value, with: { (snapshot) in
                        let _trainer = snapshot.value as! NSDictionary
                        let mTrainer = Trainer.init(withDic: _trainer)
                        mTrainer.id = trainerId
                        mWorkout.trainer = mTrainer
                        group.leave()
                    })
                }
                group.notify(queue: .main) {
                    print("All callbacks are completed")
                    spinnerActivity.hide(animated: true)
                    self.workoutCollectionView.reloadData()
                }
            }else{
                spinnerActivity.hide(animated: true)
            }
        })
    }
    @IBAction func onBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func onPressedSort(_ sender: Any) {
        self.sortView.isHidden = !self.sortView.isHidden
        if self.sortView.isHidden {
            self.mainView.frame.origin.y = 64
        }else{
            self.mainView.frame.origin.y += self.sortView.frame.height
        }
    }
    @IBAction func onTapedWorkoutImage(_ sender: Any) {
        if selectedWorkout != nil {
            let startWorkoutVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "StartWorkoutVC") as! StartWorkoutVC
            selectedWorkout.gym = self.gym
            selectedWorkout.trainer.photo = self.trainerImageView.image
            selectedWorkout.photo = self.workoutImageView.image
            startWorkoutVC.workout = self.selectedWorkout
            self.navigationController?.pushViewController(startWorkoutVC, animated: true)
        }
    }
    
    //MARK: CollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return workouts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WorkoutCollectionCell", for: indexPath) as! WorkoutCollectionCell

        let workout = self.workouts[indexPath.row]
        
        cell.workoutNameLabel.text = workout.name
        cell.gradientLayer = Helper.insertGradientLayer(target: cell.workoutImageView)

        let reference = storageRef.child(workout.photoUrl)
        let placeholderImage = UIImage(named: "placeholder_fitness.png")
        cell.workoutImageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
        
        if indexPath.row == 0 {
            self.selectedWorkout = workout
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width/3, height: collectionView.frame.width/3)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedWorkout = workouts[indexPath.row]
    }
//    
//    // MARK: - Navigation
//
//    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        // Get the new view controller using segue.destinationViewController.
//        // Pass the selected object to the new view controller.
//    }

}
