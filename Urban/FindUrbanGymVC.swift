//
//  FindUrbanGymVC.swift
//  Urban
//
//  Created by Kangtle on 8/8/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import GooglePlacePicker
import Firebase
import FirebaseStorage

class FindUrbanGymVC: UIViewController, UITableViewDelegate, UITableViewDataSource, GMSMapViewDelegate {
    var placesClient: GMSPlacesClient!
    @IBOutlet weak var btnFind: UIButton!
    @IBOutlet weak var findingView: UIView!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var gymTable: UITableView!
    @IBOutlet weak var resultView: UIView!
    
    var ref: DatabaseReference!
    let storageRef = Storage.storage().reference()

    var nearbyGyms:Array<Gym> = Array()
    
    var isFinding = false
    
    var selectedGym:Gym?
    
    var distanceUnit: String!
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
        distanceUnit = UserDefaults.standard.string(forKey: "distance_unit") ?? "Km"
    }

    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        //        navigationController?.setNavigationBarHidden(true, animated: false)

        ref = Database.database().reference()
        
        distanceUnit = UserDefaults.standard.string(forKey: "distance_unit") ?? "Km"

        mapView.delegate = self
        if locManager.location != nil {
            let curLocation = locManager.location?.coordinate
            
            let camera = GMSCameraPosition.camera(withLatitude: (curLocation?.latitude)!, longitude: (curLocation?.longitude)!, zoom: 12.0)
            mapView.camera = camera
            
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: curLocation!.latitude,
                                                     longitude: curLocation!.longitude)
            marker.title = "My Location"
            marker.map = mapView
        }
    }
    
    func originalView() {
        btnFind.isHidden = false
        findingView.isHidden = true
        resultView.isHidden = true
        navigationController?.setNavigationBarHidden(true, animated: true)
        tabBarController?.tabBar.isHidden = false
    }
    
    @IBAction func onPressedFindBtn(_ sender: Any) {
        if locManager.location == nil {
            Helper.showMessage(target: self, title: "", message: "Can't find your location")
            return
        }
        
        isFinding = true
        btnFind.isHidden = true
        findingView.isHidden = false
        tabBarController?.tabBar.isHidden = true
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        self.nearbyGyms.removeAll()
        
        ref.child("gyms").observeSingleEvent(of: .value, with: { (snapshot) in
            let gyms = snapshot.value as? NSDictionary ?? [:]
            
            let group = DispatchGroup()
            
            for (_key, _gym) in gyms {

                group.enter()
                
                let workoutRef = self.ref.child("workouts").queryOrdered(byChild: "gym_id").queryEqual(toValue: _key as! String)
                workoutRef.observeSingleEvent(of: .value, with: { (snapshot) in

                    group.leave()

                    if snapshot.exists() {
                        let mGym = Gym(withDic: _gym as! NSDictionary)
                        mGym.id = _key as! String
                        
                        if mGym.distanceFromMe(distanceUnit: self.distanceUnit) < 10000 {
                            self.nearbyGyms.append(mGym)
                        }
                    }
                })
            }
            
            group.notify(queue: .main){
                self.nearbyGyms.sort{$0.distanceFromMe(distanceUnit: self.distanceUnit)<$1.distanceFromMe(distanceUnit: self.distanceUnit)}
                if self.isFinding {
                    self.findingView.isHidden = true
                    self.resultView.isHidden = false
                    self.gymTable.reloadData()
                }
            }
        }) { (error) in

            print(error.localizedDescription)

        }

    }
    
    @IBAction func onPressCanceledSearch(_ sender: Any) {
        self.isFinding = false
        self.originalView()
    }
    @IBAction func onPressedHandle(_ sender: Any) {
    }
    
    func insertTestGyms(){
        ref.child("gyms").childByAutoId().setValue(
            [
                "name" : "Urban gym 1",
                "photo_url" : "asfa",
                "address" : "adfas",
                "location" : [
                    "lat" : 29.294822,
                    "long" : 128.248722
                ]
            ]
        )
    }
    
    //Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.nearbyGyms.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GymTableViewCell", for: indexPath) as? GymTableViewCell

        let gym = nearbyGyms[indexPath.row]
        
        let marker = GMSMarker()
        marker.position = gym.location
        marker.title = gym.name
        marker.snippet = gym.address
        marker.icon = UIImage(named: "circle_marker")
        marker.map = self.mapView
        
        cell?.gymNameLabel.text = gym.name
        cell?.gymAddressLabel.text = gym.address
        cell?.distanceLabel.text = "\(gym.distanceFromMe(distanceUnit: self.distanceUnit))" + ((distanceUnit == "Km") ? " km" : " m")
        cell?.adjustCell()
        
        let reference = storageRef.child(gym.photoUrl)
        let placeholderImage = UIImage(named: "placeholder_gym.png")
        cell?.gymImageView.sd_setImage(with: reference, placeholderImage: placeholderImage)

        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedGym = nearbyGyms[indexPath.row]
        self.performSegue(withIdentifier: "getDirection", sender: self)
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        let location = marker.position
        self.selectedGym = nearbyGyms.first(where: { $0.location.latitude == location.latitude && $0.location.longitude == location.longitude })
        if selectedGym == nil {
            return true
        }
        tabBarController?.tabBar.isHidden = true
        navigationController?.setNavigationBarHidden(false, animated: true)
        self.performSegue(withIdentifier: "getDirection", sender: self)
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let getDirectionVC = segue.destination as! GetDirectionVC
        
        getDirectionVC.gym = self.selectedGym

    }
    
}
