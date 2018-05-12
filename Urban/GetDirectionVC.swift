//
//  GetDirectionVC.swift
//  Urban
//
//  Created by Kangtle on 8/10/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import GoogleMaps

class GetDirectionVC: UIViewController, GMSMapViewDelegate {
    
    var gym: Gym! = nil
    
    @IBOutlet weak var gymNameLabel: UILabel!
    @IBOutlet weak var gymAddressLabel: UILabel!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var gymPhotoImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.gymNameLabel.text = gym.name
        self.gymAddressLabel.text = gym.address
//        self.gymPhotoImage.image = gym.thumb
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
    
        _ = Helper.insertGradientLayer(target: gymPhotoImage)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func onPressedGetDirection(_ sender: Any) {
        //1
        let optionMenu = UIAlertController(title: nil, message: "Open with", preferredStyle: .actionSheet)
        
        // 2
        let deleteAction = UIAlertAction(title: "Google Maps", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in

            let url = URL(string:"http://maps.google.com/?daddr=\(self.gym.address.replacingOccurrences(of: " ", with: "+"))")
            
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url!, options: [:], completionHandler: nil)
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(url!)
            }
            print("Google Maps")
            self.performSegue(withIdentifier: "ExploreGymVC", sender: self)
        })
        let saveAction = UIAlertAction(title: "Apple Maps", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Apple Maps")
            let url = URL(string:"http://maps.apple.com/?daddr=\(self.gym.address.replacingOccurrences(of: " ", with: "+"))")
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url!, options: [:], completionHandler: nil)
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(url!)
            }
            self.performSegue(withIdentifier: "ExploreGymVC", sender: self)
        })
        
        //
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        
        
        // 4
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(saveAction)
        optionMenu.addAction(cancelAction)
        
        // 5
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    @IBAction func onBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        self.performSegue(withIdentifier: "ExploreGymVC", sender: self)
        return true
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        print("explore")
        let exploreGymVC = segue.destination as! ExploreGymVC
        exploreGymVC.gym = self.gym
    }

}
