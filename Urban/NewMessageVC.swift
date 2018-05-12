//
//  NewMessageVC.swift
//  Urban
//
//  Created by Kangtle on 8/21/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class NewMessageVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    var ref = Database.database().reference()
    let storageRef = Storage.storage().reference()
    
    var trainers:Array<Trainer> = Array()
    var searchedTrainers: Array<Int> = Array()
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var trainerTable: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.backgroundImage = UIImage()
        self.getTrainers()
        // Do any additional setup after loading the view.
    }
    
    func getTrainers(){
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Please wait..."
        
        self.ref.child("trainers").observeSingleEvent(of: .value, with: { (snapshot) in
            if let _trainers = snapshot.value {
                for (_key, _trainer) in _trainers  as! NSDictionary {
                    let mTrainer = Trainer(withDic: _trainer as! NSDictionary)
                    mTrainer.id = _key as! String
                    
                    self.trainers.append(mTrainer)
                    self.searchedTrainers.append(self.trainers.count-1)
                }
            }
            spinnerActivity.hide(animated: true)
            self.trainerTable.reloadData()
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
        cell?.trainerImageView.sd_setImage(with: reference, placeholderImage: placeholderImage){(photo, error, _, _) in
            mTrainer.photo = photo
        }
        
        cell?.backgroundColor = UIColor.clear
        return cell!
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.endEditing(true)

        let trainerIndex = self.searchedTrainers[indexPath.row]
        let mTrainer = self.trainers[trainerIndex]

        let chatVC = ChatVC()
        let channel = ChatChannel.init(channelId: "\(Auth.auth().currentUser?.uid ?? "")_\(mTrainer.id ?? "")")
        let opponent = Opponent.init(id: mTrainer.id, name: mTrainer.name, photoUrl: mTrainer.photoUrl, photo: mTrainer.photo)
        channel.opponent = opponent
        chatVC.channel = channel
        let chatNavigationController = UINavigationController(rootViewController: chatVC)
        present(chatNavigationController, animated: true, completion: nil)

    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = UIColor.init(rgb: 0x2D2E40).withAlphaComponent(0.8)
        return indexPath
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
    
    @IBAction func onBack(_ sender: Any) {
        self.view.endEditing(true)
        self.performSegueToReturnBack()
    }
    @IBAction func onPressedSearch(_ sender: Any) {
//        self.trainerTable.scrollToRow(at: IndexPath.init(row: 0, section: 0), at: .top, animated: true)
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
