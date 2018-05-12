//
//  SelectTrainerVC.swift
//  Urban
//
//  Created by Kangtle on 8/12/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class SelectTrainerVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    var ref: DatabaseReference!
    let storageRef = Storage.storage().reference()

    var trainers:Array<Trainer> = Array()
    var searchedTrainers: Array<Int> = Array()
    var configVC: SelectWorkoutConfigVC!
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var trainerTable: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.ref = Database.database().reference()
        self.getTrainers()
        self.searchBar.becomeFirstResponder()
        // Do any additional setup after loading the view.
    }

    func getTrainers(){
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Please wait..."
        
        self.ref.child("gym_trainers/\(configVC.gym.id!)").observeSingleEvent(of: .value, with: { (snapshot) in
            let gymTrainers = snapshot.value as? NSDictionary ?? [:]
            let group = DispatchGroup()
            for (_key, _) in gymTrainers {
                group.enter()
                self.ref.child("trainers/\(_key as! String)").observeSingleEvent(of: .value, with: { (snapshot) in
                    let _trainer = snapshot.value as? NSDictionary
                    let mTrainer = Trainer(withDic: _trainer!)
                    mTrainer.id = _key as! String
                    
                    self.trainers.append(mTrainer)
                    self.searchedTrainers.append(self.trainers.count-1)
                    group.leave()
                }) { (error) in
                    
                    print(error.localizedDescription)
                    
                }
            }
            group.notify(queue: .main) {
                print("All callbacks are completed")
                spinnerActivity.hide(animated: true)
                self.trainerTable.reloadData()
            }
        })

    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchedTrainers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrainerTableCell", for: indexPath) as? TrainerTableCell
        
        let trainerIndex = self.searchedTrainers[indexPath.row]
        let mTrainer = self.trainers[trainerIndex]
        
        cell?.trainerNameLabel.text = mTrainer.name
        cell?.trainerQualificationLabel.text = mTrainer.fitnessQualification
        cell?.trainerRating = mTrainer.rating

        let reference = storageRef.child(mTrainer.photoUrl)
        let placeholderImage = UIImage(named: "placeholder_user.png")
        cell?.trainerImageView.sd_setImage(with: reference, placeholderImage: placeholderImage)

        return cell!

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        let trainerView = configVC.trainerView

        trainerView?.addSubview(cell!)
        cell?.frame = CGRect(x: 0, y: 0, width: (trainerView?.frame.width)!, height: (trainerView?.frame.height)!)
        
        configVC.trainerView.isHidden = false
        configVC.searchBar.isHidden = true
        
        let trainerIndex = self.searchedTrainers[indexPath.row]
        configVC.selectedTrainer = self.trainers[trainerIndex]
        
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("search", searchText)
        
        self.searchedTrainers.removeAll()
        
        for (index, trainer) in trainers.enumerated() {
            if(trainer.name.lowercased().range(of: searchText.lowercased()) != nil || searchText == ""){
                self.searchedTrainers.append(index)
            }
        }
        trainerTable.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
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
