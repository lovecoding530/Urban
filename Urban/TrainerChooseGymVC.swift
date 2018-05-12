//
//  TrainerChooseGymVC.swift
//  Urban
//
//  Created by Kangtle on 8/29/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import CoreLocation

class TrainerChooseGymVC: UIViewController,
                          UITableViewDelegate, UITableViewDataSource,
                          UISearchBarDelegate{

    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var gymTable: UITableView!
    
    let storageRef = Storage.storage().reference()
    var ref = Database.database().reference()
    var nearbyGyms:Array<Gym> = Array()
    var searchedGyms = [Int]()

    var onDoneBlock: ((Gym) -> Void)?
    var distanceUnit: String!

    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.black]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.white]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if onDoneBlock == nil {
            self.navigationItem.leftBarButtonItem = nil
            self.navigationItem.title = "MY URBAN GYMS"
        }
        
        distanceUnit = UserDefaults.standard.string(forKey: "distance_unit") ?? "Km"

        
        searchBar.delegate = self
        
        getNearbyGyms()
        // Do any additional setup after loading the view.
    }
    
    func getNearbyGyms() {
        if locManager.location == nil {
            Helper.showMessage(target: self, title: "", message: "Can't find your location")
            return
        }

        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Please wait..."

        self.nearbyGyms.removeAll()
        
        let uid = Auth.auth().currentUser?.uid ?? ""
        var gymRef: DatabaseQuery
//        if onDoneBlock == nil {
            gymRef = ref.child("gyms").queryOrdered(byChild: "trainer_id").queryEqual(toValue: uid)
//        }else{
//            gymRef = ref.child("gyms")
//        }
        
        gymRef.observe(.value, with: { (snapshot) in
            self.nearbyGyms.removeAll()
            self.searchedGyms.removeAll()
            let gyms = snapshot.value as? NSDictionary ?? [:]
            for (_key, _gym) in gyms {
                let mGym = Gym(withDic: _gym as! NSDictionary)
                mGym.id = _key as! String
                
                if(mGym.distanceFromMe(distanceUnit: self.distanceUnit) < 10000){
                    self.nearbyGyms.append(mGym)
                    self.searchedGyms.append(self.nearbyGyms.count - 1)
                }
            }
            self.nearbyGyms.sort{$0.distanceFromMe(distanceUnit: self.distanceUnit)<$1.distanceFromMe(distanceUnit: self.distanceUnit)}
            self.gymTable.reloadData()
            spinnerActivity.hide(animated: true)
        }) { (error) in
            
            print(error.localizedDescription)
            spinnerActivity.hide(animated: true)
            
        }
    }
    @IBAction func onClose(_ sender: Any) {
        self.view.endEditing(true)
        self.performSegueToReturnBack()
    }
    
    //MARK: Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchedGyms.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < searchedGyms.count{
            let cell = tableView.dequeueReusableCell(withIdentifier: "GymTableViewCell", for: indexPath) as? GymTableViewCell

            let gymIndex = searchedGyms[indexPath.row]
            let gym = nearbyGyms[gymIndex]
            
            cell?.gymNameLabel.text = gym.name
            cell?.gymAddressLabel.text = gym.address
            cell?.distanceLabel.text = "\(gym.distanceFromMe(distanceUnit: self.distanceUnit))" + ((distanceUnit == "Km") ? " km" : " m")
            cell?.adjustCell()
            
            let reference = storageRef.child(gym.photoUrl)
            let placeholderImage = UIImage(named: "placeholder_gym.png")
            cell?.gymImageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
            
            return cell!
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "newUrbanGym", for: indexPath)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row)
        if indexPath.row < searchedGyms.count {
            if (self.onDoneBlock != nil) {
                let gymIndex = searchedGyms[indexPath.row]
                let selectedGym = self.nearbyGyms[gymIndex]
                self.onDoneBlock!(selectedGym)
            }
        }
    }
    
    // MARK: Search bar
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        searchBar.showsCancelButton = false
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("search", searchText)
        
        self.searchedGyms.removeAll()
        
        for (index, gym) in nearbyGyms.enumerated() {
            if(gym.name.lowercased().range(of: searchText.lowercased()) != nil || searchText == ""){
                self.searchedGyms.append(index)
            }
        }
        gymTable.reloadData()
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
