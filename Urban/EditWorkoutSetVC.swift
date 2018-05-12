//
//  EditWorkoutSetVC.swift
//  Urban
//
//  Created by Kangtle on 8/29/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import FirebaseStorage

class EditWorkoutSetVC: UIViewController,
                        UITextViewDelegate,
                        UITextFieldDelegate{

    @IBOutlet weak var setDescTextView: UITextView!
    @IBOutlet weak var durationField: UITextField!
    @IBOutlet weak var setVideoThumbView: UIImageView!
    @IBOutlet weak var durationView: UIView!
    @IBOutlet weak var repsView: UIView!
    @IBOutlet weak var repsField: UITextField!
    
    
    let textViewPlaceholder = "Enter description of workout"
    let textViewPlaceholderColor = UIColor.lightGray
    let textViewTextColor = UIColor.white
    
    var editingSet: WorkoutSet? = nil
    let storageRef = Storage.storage().reference()

    var onDoneBlock: ((WorkoutSet, Bool) -> Void)!
    
    var isNewSet: Bool!

    override func viewDidLoad() {
        super.viewDidLoad()
        setVideoThumbView.layer.cornerRadius = 5
        setVideoThumbView.clipsToBounds = true
        
        var repsArray = Array(1...100).map
        {
            String($0)
        }
        repsArray.insert("", at: 0)
        
        self.repsField.loadDropdownData(data: repsArray)
        self.repsField.delegate = self
        self.durationField.delegate = self
        
        if editingSet == nil {
            isNewSet = true
            editingSet = WorkoutSet()
        }else{
            isNewSet = false
            
            let reference = self.storageRef.child((editingSet?.thumbUrl)!)
            self.setVideoThumbView.sd_setImage(with: reference)
            
            self.setDescTextView.text = editingSet?.description
            self.durationField.text = String(describing: editingSet?.duration ?? 0)
            self.repsField.setTextWithPickerView(text: String(describing: editingSet?.reps ?? 0))
        }
        // Do any additional setup after loading the view.
    }

    @IBAction func onBack(_ sender: Any) {
        self.performSegueToReturnBack()
    }
    @IBAction func onDone(_ sender: Any) {
        editingSet?.description = setDescTextView.text
        editingSet?.duration = Int(durationField.text!) ?? 0
        editingSet?.reps = Int(repsField.text!) ?? 0
        if editingSet?.videoUrl == nil {
            Helper.showMessage(target: self, title: "", message: "Add a video")
            return
        }
        if (editingSet?.description.isEmpty)! {
            Helper.showMessage(target: self, title: "", message: "Enter set's description")
            return
        }
        if editingSet?.duration == 0 && editingSet?.reps == 0 {
            Helper.showMessage(target: self, title: "", message: "Enter set's duration or reps")
            return
        }
        self.performSegueToReturnBack()
        self.onDoneBlock(editingSet!, isNewSet)
    }
    @IBAction func onTappedAddaVideo(_ sender: Any) {
        let chooseVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TrainerVideosVC") as! TrainerVideosVC
        chooseVC.onDoneBlock = {(videoUrl, videoThumbUrl) in
            chooseVC.performSegueToReturnBack()
            self.editingSet?.videoUrl = videoUrl
            self.editingSet?.thumbUrl = videoThumbUrl

            let reference = self.storageRef.child(videoThumbUrl)
            self.setVideoThumbView.sd_setImage(with: reference)
        }
        self.navigationController?.pushViewController(chooseVC, animated: true)
    }
    
    
    //textview
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == textViewPlaceholderColor {
            textView.text = nil
            textView.textColor = textViewTextColor
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = textViewPlaceholder
            textView.textColor = textViewPlaceholderColor
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField === repsField {
            if (textField.text?.isEmpty)! {
                durationView.isHidden = false
            }else{
                durationView.isHidden = true
            }
        }else{
            if (textField.text?.isEmpty)! || textField.text == "0" {
                repsView.isHidden = false
            }else{
                repsView.isHidden = true
            }
        }
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
