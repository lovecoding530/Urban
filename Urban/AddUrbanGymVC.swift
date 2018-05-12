//
//  AddUrbanGymVC.swift
//  Urban
//
//  Created by Kangtle on 9/17/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase
import FirebaseStorage

class AddUrbanGymVC: UIViewController, GMSMapViewDelegate {

    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var gymNameField: UITextField!
    @IBOutlet weak var gymDescriptionField: UITextView!
    
    let marker = GMSMarker()
    var ref = Database.database().reference()
    let storageRef = Storage.storage().reference()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true

        marker.icon = UIImage(named: "circle_marker")
        marker.title = "My Location"
        marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        marker.map = mapView
        

        if locManager.location != nil {
            let curLocation = locManager.location?.coordinate
            
            let camera = GMSCameraPosition.camera(withLatitude: (curLocation?.latitude)!,
                                                     longitude: (curLocation?.longitude)!, zoom: 16.0)
            mapView.camera = camera
            
            marker.position = CLLocationCoordinate2D(latitude: curLocation!.latitude,
                                                    longitude: curLocation!.longitude)
        }

        // Do any additional setup after loading the view.
    }

    //MARK: IBActions
    @IBAction func onBack(_ sender: Any) {
        self.performSegueToReturnBack()
    }
    
    @IBAction func onAddNew(_ sender: Any) {
        let uid = Auth.auth().currentUser?.uid ?? ""
        let gymName = gymNameField.text
        let gymDescription = gymDescriptionField.text
        let gymLocation = marker.position
        
        if (gymName?.isEmpty)! {
            return
        }
        if (gymDescription?.isEmpty)! {
            return
        }

        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Please wait..."

        let geocoder = GMSGeocoder()
        geocoder.reverseGeocodeCoordinate(gymLocation) { (response, error) in
            guard error == nil else {
                spinnerActivity.hide(animated: true)
                Helper.showMessage(target: self, title: "", message: (error?.localizedDescription)!)
                return
            }
            
            if let result = response?.firstResult() {
                let address = result.lines?[0]
                print(address ?? "")
                
                let gymDic: [String : Any] = [
                    "trainer_id": uid,
                    "name": gymName ?? "",
                    "description": gymDescription ?? "",
                    "location": [
                        "lat": gymLocation.latitude,
                        "long": gymLocation.longitude
                    ],
                    "address": address ?? "",
                    "photo_url": "no photo"
                ]
                self.ref.child("gyms").childByAutoId().setValue(gymDic)
                self.performSegueToReturnBack()
            }else{
                Helper.showMessage(target: self, title: "", message: "Can't find your address")
            }
        }
    }

    //MARK: Map view
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        self.marker.position = coordinate
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
