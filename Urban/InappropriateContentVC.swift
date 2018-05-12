//
//  InappropriateContentVC.swift
//  Urban
//
//  Created by Kangtle on 11/22/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class InappropriateContentVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var contents = [WorkoutSet]()
    var contentIDs = [[String:Any]]()

    let dbRef = Database.database().reference()
    let storageRef = Storage.storage().reference()
    
    var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true

        getContents()
        // Do any additional setup after loading the view.
    }
    
    func getContents(){
        let inapproRef = dbRef.child("inappropriate_contents")
        self.isLoading = true
        
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Loading..."
        
        inapproRef.observe(.value, with: { (snapshot) in
            if let rows = snapshot.value as? [String:Any] {

                self.contents.removeAll()
                self.contentIDs.removeAll()
                
                for (key, row) in rows {
                    var contentDic = row as? [String: Any]
                    let workoutId = contentDic?["workout_id"] as? String ?? ""
                    let setId = contentDic?["set_id"] as? String ?? ""
                    
                    let setRef = self.dbRef.child("sets/\(workoutId)/\(setId)")
                    setRef.observeSingleEvent(of: .value, with: { (setSnapshot) in
                        if let setDic = setSnapshot.value as? NSDictionary {
                            let mSet = WorkoutSet.init(withDic: setDic)
                            self.contents.append(mSet)
                            
                            contentDic?["key"] = key
                            
                            self.contentIDs.append(contentDic!)
                            
                            self.tableView.reloadData()
                        }
                    })
                }
            }else{
                self.contentIDs.removeAll()
                self.contents.removeAll()
                self.tableView.reloadData()
            }
            
            if self.isLoading {
                self.isLoading = false
                spinnerActivity.hide(animated: true)
            }
        })
    }
    
    @IBAction func onSignout(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            let signinNC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SigninNC") as! UINavigationController
            APPDELEGATE.window?.rootViewController = signinNC
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewSetVC = segue.destination as! ViewSetVC
        
        let selectedRow = self.tableView.indexPathForSelectedRow?.row
        viewSetVC.set = contents[selectedRow!]
        viewSetVC.contentId = contentIDs[selectedRow!]
    }
}

extension InappropriateContentVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SetTableViewCell", for: indexPath) as! SetTableViewCell
        let set = contents[indexPath.row]
        
        cell.setDescriptionLabel.text = set.description
        cell.setDurationLabel.text = "\(String(set.duration)) min"
        
        let reference = storageRef.child(set.thumbUrl)
        let placeholderImage = UIImage(named: "placeholder_fitness.png")
        cell.setImageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "ViewSet", sender: self)
    }
}
