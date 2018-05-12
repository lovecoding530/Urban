//
//  WorkoutsVC.swift
//  Urban
//
//  Created by Kangtle on 8/9/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorageUI

class WorkoutsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var ref: DatabaseReference!
    let storageRef = Storage.storage().reference()
    typealias WorkoutHistories = Array<WorkoutHistory>
    
    var workoutsDic: Dictionary<String, WorkoutHistories> = Dictionary()
    
    @IBOutlet weak var historyTable: UITableView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var durationLabel: UILabel!
    
    var fromTimeStamp: Int64 = Int64(Date().timeIntervalSince1970)
    var toTimeStamp: Int64 = Int64(Date().timeIntervalSince1970)
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true

        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: UIBarPosition.any, barMetrics: UIBarMetrics.default)
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        toolbar.isTranslucent = true
        
        ref = Database.database().reference()
        
        historyTable.delegate = self
        historyTable.dataSource = self
        
        let historyRef = ref.child("workout_history/\(Auth.auth().currentUser?.uid ?? "")")
        let searchRef = historyRef.queryOrdered(byChild: "time").queryEnding(atValue: fromTimeStamp).queryLimited(toLast: 3)
        
        getWorkoutHistories(withRef: searchRef)

        // Do any additional setup after loading the view.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return workoutsDic.keys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Array(workoutsDic.values)[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WorkoutHistoryTableCell", for: indexPath) as! WorkoutHistoryTableCell

        let history = Array(workoutsDic.values)[indexPath.section][indexPath.row]
        cell.gymNameLabel.text = history.gym.name
        cell.workoutNameLabel.text = history.workoutName

        let reference = storageRef.child(history.gym.photoUrl)
        let placeholderImage = UIImage(named: "placeholder_gym.png")
        cell.gymImageView.sd_setImage(with: reference, placeholderImage: placeholderImage)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        
        cell.durationLabel.text = "\(dateFormatter.string(from: history.startTime)) - \(dateFormatter.string(from: history.endTime))"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = UIColor.init(rgb: 0x2D2E40).withAlphaComponent(0.8)
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = UIColor.clear
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let returnedView = UIView() //set these values as necessary
        returnedView.backgroundColor = UIColor.clear
        
        let label = UILabel(frame: CGRect(x: 18, y: 10, width: 150, height: 20))
        label.font = UIFont(name: "Helvetica", size: 11)
        label.textColor = UIColor.init(rgb: 0xF5515F)
        label.text = Array(workoutsDic.keys)[section]
        returnedView.addSubview(label)
        
        return returnedView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let history = Array(workoutsDic.values)[indexPath.section][indexPath.row]
        let workoutId = history.workoutId
        let workoutRef = ref.child("/workouts/\(workoutId ?? "")")
        workoutRef.observeSingleEvent(of: .value, with: { snapshot in
            guard let workoutDic = snapshot.value as? NSDictionary else { return }
            let mWorkout = Workout.init(withDic: workoutDic)
            mWorkout.id = workoutId
            mWorkout.gym = history.gym

            let trainerId = workoutDic["trainer_id"] as! String
            let trainerRef = self.ref.child("trainers/\(trainerId)")
            trainerRef.observeSingleEvent(of: .value, with: { snapshot in
                guard let trainerDic = snapshot.value as? NSDictionary else { return }
                let mTrainer = Trainer.init(withDic: trainerDic)
                mWorkout.trainer = mTrainer

                let startWorkoutVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "StartWorkoutVC") as! StartWorkoutVC
                startWorkoutVC.workout = mWorkout
                self.tabBarController?.tabBar.isHidden = true
                startWorkoutVC.selectedSegmentioIndex = 1
                self.navigationController?.pushViewController(startWorkoutVC, animated: true)
            })
        })
    }
    
    @IBAction func onPressedPrev(_ sender: Any) {
        let historyRef = ref.child("workout_history/\(Auth.auth().currentUser?.uid ?? "")")
        let searchRef = historyRef.queryOrdered(byChild: "time").queryEnding(atValue: fromTimeStamp - 1).queryLimited(toLast: 3)
        
        getWorkoutHistories(withRef: searchRef)
    }
    
    @IBAction func onPressedNext(_ sender: Any) {
        let historyRef = ref.child("workout_history/\(Auth.auth().currentUser?.uid ?? "")")
        let searchRef = historyRef.queryOrdered(byChild: "time").queryStarting(atValue: toTimeStamp + 1).queryLimited(toFirst: 3)
        
        getWorkoutHistories(withRef: searchRef)
    }
    
    func getWorkoutHistories(withRef: DatabaseQuery) {
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Please wait..."
        
        withRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let histories = snapshot.value as? NSDictionary {
                let group = DispatchGroup()
                
                var minTimestamp: Int64 = Int64(Date().timeIntervalSince1970)
                var maxTimestamp: Int64 = 0

                self.workoutsDic.removeAll()

                for (_, _history) in histories {
                    group.enter()
                    
                    let mHistory = WorkoutHistory(withDic: _history as! NSDictionary)
                    
                    if mHistory.timeStamp < minTimestamp {
                        minTimestamp = mHistory.timeStamp
                    }
                    
                    if mHistory.timeStamp > maxTimestamp {
                        maxTimestamp = mHistory.timeStamp
                    }
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "d MMM, EEEE"
                    let key = dateFormatter.string(from: mHistory.startTime)
                    
                    if(self.workoutsDic[key] == nil){
                        self.workoutsDic[key] = Array()
                    }
                    
                    self.workoutsDic[key]?.append(mHistory)
                    
                    self.ref.child("gyms/\(mHistory.gymId ?? "")").observeSingleEvent(of: .value, with: { (snapshot) in
                        let _gym = snapshot.value as? NSDictionary
                        let mGym = Gym(withDic: _gym!)
                        mGym.id = mHistory.gymId
                        mHistory.gym = mGym
                        group.leave()
                    }) { (error) in
                        
                        print(error.localizedDescription)
                        
                    }
                }
                group.notify(queue: .main) {
                    print("All callbacks are completed")
                    spinnerActivity.hide(animated: true)
                    self.historyTable.reloadData()
                }
                
                self.toTimeStamp = maxTimestamp
                self.fromTimeStamp = minTimestamp
                
                let fromDate = Date.init(timeIntervalSince1970: TimeInterval(self.fromTimeStamp))
                let toDate = Date.init(timeIntervalSince1970: TimeInterval(self.toTimeStamp))
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "d MMM"
                
                self.durationLabel.text = "\(dateFormatter.string(from: fromDate)) - \(dateFormatter.string(from: toDate))"
            }else{
                spinnerActivity.hide(animated: true)
            }
        })

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
