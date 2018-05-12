//
//  ViewSetVC.swift
//  Urban
//
//  Created by Kangtle on 11/22/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Firebase
import FirebaseStorage

class ViewSetVC: UIViewController {
    
    var player: AVPlayer?
    var avpController = AVPlayerViewController()

    @IBOutlet weak var setDescLabel: UILabel!
    @IBOutlet weak var videoView: UIView!
    
    var set: WorkoutSet!
    var contentId: [String: Any]!
    
    let storageRef = Storage.storage().reference()
    var dbRef = Database.database().reference()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.avpController = AVPlayerViewController()
        avpController.view.frame = videoView.frame
        self.addChildViewController(avpController)
        self.view.addSubview(avpController.view)

        setupSet()
        // Do any additional setup after loading the view.
    }

    func setupSet(){
        setDescLabel.text = set.description
        
        storageRef.child(set.videoUrl).downloadURL(){  url, error in
            if error == nil {
                let player = AVPlayer(url: url!)
                self.avpController.player = player
            }
        }
    }
    
    @IBAction func onBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func onDeleteSet(_ sender: Any) {
        let alert = UIAlertController(title: "URBAN", message: "Are you sure to delete the set?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default)
        {
            (result : UIAlertAction) -> Void in

            let key = self.contentId["key"] ?? ""
            let workoutId = self.contentId["workout_id"] ?? ""
            let setId = self.contentId["set_id"] ?? ""

            let inApproRef = self.dbRef.child("inappropriate_contents/\(key)")
            inApproRef.removeValue()
            
            let deleteSetRef = self.dbRef.child("sets/\(workoutId)/\(setId)")
            deleteSetRef.removeValue()

            self.performSegueToReturnBack()
        }
        let cancelAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
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
