//
//  TrainerWorkoutsVC.swift
//  Urban
//
//  Created by Kangtle on 8/27/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import BGTableViewRowActionWithImage

class TrainerWorkoutsVC: UIViewController,
                         UITableViewDelegate, UITableViewDataSource {
    
    let storageRef = Storage.storage().reference()
    var ref = Database.database().reference()
    var workouts = [Workout]()

    var isLoaded = false
    @IBOutlet weak var workoutTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true

        // Do any additional setup after loading the view.
        
        getWorkouts()
        
    }
    
    func getWorkouts(){
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Please wait..."
        
        let uid = Auth.auth().currentUser?.uid ?? ""
//        let uid = "first"
        let workoutRef = self.ref.child("workouts").queryOrdered(byChild: "trainer_id").queryEqual(toValue: uid)
        
        workoutRef.observe(.value, with: { (snapshot) in
            if let _workouts = snapshot.value as? NSDictionary {
                
                self.workouts.removeAll()
                
                let group = DispatchGroup()
                for (_key, _workout) in _workouts {
                    let mWorkout = Workout(withDic: _workout as! NSDictionary)
                    mWorkout.id = _key as! String
                    
                    self.workouts.append(mWorkout)
                    
                    group.enter()
                    let gymId = mWorkout.gymId ?? ""
                    self.ref.child("gyms/\(gymId)").observeSingleEvent(of: .value, with: { (snapshot) in
                        if let _gym = snapshot.value as? NSDictionary {
                            let mGym = Gym.init(withDic: _gym)
                            mGym.id = gymId
                            mWorkout.gym = mGym
                        }
                        group.leave()
                    })
                }
                group.notify(queue: .main) {
                    print("All callbacks are completed")
                    if !self.isLoaded {
                        spinnerActivity.hide(animated: true)
                        self.isLoaded = true
                    }
                    self.workoutTableView.reloadData()
                }
            }else{
                if !self.isLoaded {
                    spinnerActivity.hide(animated: true)
                    self.isLoaded = true
                }
            }
        })
    }

    //MARK: - Table View Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.workouts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! WorkoutTableViewCell
        
        let workout = self.workouts[indexPath.row]
        cell.workoutNameLabel.text = workout.name
        cell.gymLabel.text = workout.gym.address
        cell.typeAndLevelLabel.text = "\(workout.type ?? "") \u{25CF} \(workout.level ?? "")"

        let reference = storageRef.child(workout.photoUrl)
        let placeholderImage = UIImage(named: "placeholder_fitness.png")
        cell.workoutImageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
        
        cell.backgroundColor = UIColor.clear
        return cell
    }
    
//    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
//        let cell = tableView.cellForRow(at: indexPath)
//        cell?.backgroundColor = UIColor.init(rgb: 0x2D2E40).withAlphaComponent(0.8)
//        return indexPath
//    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = BGTableViewRowActionWithImage.rowAction(with: .destructive,
                                                             title: "Delete",
                                                             backgroundColor: UIColor(rgb: 0xF5515F),
                                                             image: UIImage(named: "icon_delete"),
                                                             forCellHeight: 80){(action, indexPath) in
            let alert = UIAlertController(title: "URBAN", message: "Are you sure to delete this workout?", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
            {
                (result : UIAlertAction) -> Void in
                let deleteRef = self.ref.child("workouts/\(self.workouts[(indexPath?.row)!].id ?? "")")
                deleteRef.setValue(nil)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default)
            {
                (result : UIAlertAction) -> Void in
            }
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
                                                    
        }

        let edit = BGTableViewRowActionWithImage.rowAction(with: .default,
                                                           title: "Edit ",
                                                           backgroundColor: UIColor(rgb: 0xF5515F),
                                                           image: UIImage(named: "icon_edit"),
                                                           forCellHeight: 80){(action, indexPath) in
            let editWorkoutVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EditWorkoutVC") as! EditWorkoutVC
            editWorkoutVC.fromTab = false
            editWorkoutVC.editingWorkout = self.workouts[(indexPath?.row)!]
            self.navigationController?.pushViewController(editWorkoutVC, animated: true)
        }
        
        return [edit!, delete!]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewWorkoutVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewWorkoutVC") as! ViewWorkoutVC
        viewWorkoutVC.workout = self.workouts[indexPath.row]
        self.navigationController?.pushViewController(viewWorkoutVC, animated: true)
    }

    @IBAction func onPressedAdd(_ sender: Any) {
        let editWorkoutVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EditWorkoutVC") as! EditWorkoutVC
        editWorkoutVC.fromTab = false
        self.navigationController?.pushViewController(editWorkoutVC, animated: true)
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
