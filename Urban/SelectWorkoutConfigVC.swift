//
//  SelectWorkoutConfigVC.swift
//  Urban
//
//  Created by Kangtle on 8/12/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit

class SelectWorkoutConfigVC: UIViewController, SwiftySwitchDelegate {

    @IBOutlet weak var workoutTypeSeg: SSYSegmentedControl!
    @IBOutlet weak var workoutLevelSeg: SSYSegmentedControl!
    @IBOutlet weak var unseenVideosSwitch: SwiftySwitch!
    @IBOutlet weak var specificTrainerSwitch: SwiftySwitch!
    @IBOutlet var searchBar: UIView!
    @IBOutlet weak var trainerView: UIView!
    @IBOutlet weak var gymTitleLabel: UIBarButtonItem!
    
    var gym: Gym! = nil
    var selectedTrainer: Trainer! = nil
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationItem.title = gym.name
        
        self.unseenVideosSwitch.layer.borderColor = UIColor.init(rgb: 0xF5515F).cgColor
        self.specificTrainerSwitch.layer.borderColor = UIColor.init(rgb: 0xF5515F).cgColor
        unseenVideosSwitch.delegate = self
        specificTrainerSwitch.delegate = self
        workoutTypeSeg.selectedSegmentIndex = 0
        workoutLevelSeg.selectedSegmentIndex = 0
        // Do any additional setup after loading the view.
    }
    
    @IBAction func onPressedClose(_ sender: Any) {
        self.performSegueToReturnBack()
    }

    @IBAction func onPressedCheck(_ sender: Any) {
    }
    @IBAction func onPressedSearchTrainer(_ sender: Any) {
        print("search trainer")
    }
    
    func valueChanged(sender: SwiftySwitch) {
        if(sender.isOn){
            sender.myColor = sender.dotOffColor
        }else{
            sender.myColor = UIColor.clear
        }
        if sender === specificTrainerSwitch {
            if(sender.isOn){
                self.searchBar.isHidden = false
                self.trainerView.isHidden = true
            }else{
                self.searchBar.isHidden = true
                self.trainerView.isHidden = true
            }
        }
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
        case .some("SelectTrainerVC"):
            let selectTrainerVC = segue.destination as! SelectTrainerVC
            selectTrainerVC.configVC = self
        case .some("SelectWorkoutVC"):
            let selectWorkoutVC = segue.destination as! SelectWorkoutVC
            selectWorkoutVC.gym = self.gym
            selectWorkoutVC.trainer = self.selectedTrainer
        default: break
        }
    }

}
