//
//  ExploreGymVC.swift
//  Urban
//
//  Created by Kangtle on 8/11/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import GoogleMaps

class ExploreGymVC: UIViewController, GMSMapViewDelegate {

    var gym: Gym! = nil
    
    @IBOutlet weak var gymNameLabel: UILabel!
    @IBOutlet weak var gymAddressLabel: UILabel!
    @IBOutlet weak var mapView: GMSMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.gymNameLabel.text = gym.name
        self.gymAddressLabel.text = gym.address
        self.navigationItem.setHidesBackButton(true, animated: false);
        // Do any additional setup after loading the view.
        mapView.delegate = self
        let camera = GMSCameraPosition.camera(withLatitude: (gym.location.latitude), longitude: (gym.location.longitude), zoom: 12.0)
        mapView.camera = camera
        
        let marker = GMSMarker()
        marker.position = gym.location
        marker.title = gym.name
        marker.snippet = gym.address
        marker.icon = UIImage(named: "circle_marker")
        marker.map = self.mapView
        
    }
    @IBAction func toWorkouts(_ sender: Any) {
        self.tabBarController?.selectedIndex = 0
        self.tabBarController?.tabBar.isHidden = false
        let rootView = self.navigationController?.viewControllers.first as! FindUrbanGymVC
        rootView.originalView()
        self.navigationController?.popToRootViewController(animated: false)
        
    }
    @IBAction func onBack(_ sender: Any) {
        self.performSegueToReturnBack()
    }

    @IBAction func onExplore(_ sender: Any) {
        goExplore()
    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        goExplore()
        return true
    }
    
    func goExplore() {
        //        self.performSegue(withIdentifier: "configVC", sender: self)
        self.performSegue(withIdentifier: "withoutConfigVC", sender: self)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let segueId = segue.identifier ?? ""
        if segueId == "configVC" {
            let configVC = segue.destination as! SelectWorkoutConfigVC
            configVC.gym = self.gym
        }else if segueId == "withoutConfigVC" {
            let selectWorkoutVC = segue.destination as! SelectWorkoutVC
            selectWorkoutVC.gym = self.gym
            selectWorkoutVC.trainer = nil
        }
    }

}
