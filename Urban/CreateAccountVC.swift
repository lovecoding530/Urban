//
//  CreateAccountVC.swift
//  Urban
//
//  Created by Kangtle on 8/6/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase

extension Date {
    func toString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.string(from: self)
    }
}


class CreateAccountVC: UIViewController, SwiftySwitchDelegate  {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    @IBOutlet weak var trainerView: UIView!
    @IBOutlet weak var noTrainerView: UIView!
    @IBOutlet weak var switchTrainer: SwiftySwitch!
    @IBOutlet weak var fitnessQualificationField: UITextField!
    @IBOutlet weak var yearsTextField: UITextField!
    @IBOutlet weak var numberTextField: UITextField!
    
    @IBOutlet weak var startPeriodField: UITextField!
    
    @IBOutlet weak var endPeriodField: UITextField!

    var currentField: UITextField!
    var datePicker: UIDatePicker!

    var ref: DatabaseReference!
    
    var qualifications = ["Personal trainer", "Gym instructor", "Exercise scientists", "Exercise physiologist"];
    var years = ["1 - 5 years", "5 - 10 years", "10 - 15 years"];
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        // Do any additional setup after loading the view.
        switchTrainer.delegate = self
        
        setTrainerView(isTrainer: false)
        
        fitnessQualificationField.loadDropdownData(data: qualifications)
        yearsTextField.loadDropdownData(data: years)
        
        self.datePicker = UIDatePicker()
        self.datePicker.datePickerMode = UIDatePickerMode.date
        self.datePicker.addTarget(self, action: #selector(datePickerValueChanged), for: UIControlEvents.valueChanged)
        
        self.switchTrainer.layer.borderColor = UIColor.init(rgb: 0xF5515F).cgColor
    }
    
    
    @IBAction func onPressedCreateAccount(_ sender: Any) {
        print("create account", nameTextField.text!)
        let name = nameTextField.text
        let email = emailTextField.text
        let password = passwordTextField.text
        let confirmPassword = confirmPasswordTextField.text
        
        let qualification = fitnessQualificationField.text
        let yearsOfExperience = yearsTextField.text
        let registrationNumber = numberTextField.text
        let startPeriod = startPeriodField.text
        let endPeriod = endPeriodField.text

        if (name == "") {
            Helper.showMessage(target: self, title: "", message: "Please enter correctly"){
                self.nameTextField.becomeFirstResponder()
            }
            return
        }
        if (!Helper.isValidEmail(email: email!)) {
            Helper.showMessage(target: self, title: "", message: "Please enter correctly"){
                self.emailTextField.becomeFirstResponder()
            }
            return
        }
        if (password == "") {
            Helper.showMessage(target: self, title: "", message: "Please enter correctly"){
                self.passwordTextField.becomeFirstResponder()
            }
            return
        }
        if (confirmPassword == "") {
            Helper.showMessage(target: self, title: "", message: "Please enter correctly"){
                self.confirmPasswordTextField.becomeFirstResponder()
            }
            return
        }
        if (password != confirmPassword){
            Helper.showMessage(target: self, title: "", message: "Please enter correctly"){
                self.passwordTextField.becomeFirstResponder()
            }
            return
        }
        
        if(switchTrainer.isOn){
            if(qualification == "" || yearsOfExperience == "" || registrationNumber == "" || startPeriod == "" || endPeriod == ""){
                Helper.showMessage(target: self, title: "", message: "Please enter all fields")
                return
            }
        }

        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Please wait..."
        Auth.auth().createUser(withEmail: email!, password: password!){ (user, error) in
            if(error == nil){
                let userDefault = UserDefaults.standard
                let uid:String = (user?.uid)!
                let inviteFrom = userDefault.string(forKey: "invite_from")
                if(self.switchTrainer.isOn){
                    self.ref.child("trainers/\(uid)/name").setValue(name)
                    self.ref.child("trainers/\(uid)/email").setValue(email)
                    self.ref.child("trainers/\(uid)/fitness_qualification").setValue(qualification)
                    self.ref.child("trainers/\(uid)/years_of_experience").setValue(yearsOfExperience)
                    self.ref.child("trainers/\(uid)/registration_number").setValue(registrationNumber)
                    self.ref.child("trainers/\(uid)/start_period").setValue(startPeriod)
                    self.ref.child("trainers/\(uid)/end_period").setValue(endPeriod)
                    self.ref.child("trainers/\(uid)/membership_at").setValue(Int64(Date().timeIntervalSince1970))
                    self.ref.child("trainers/\(uid)/membership_num").setValue(0)
                    if(inviteFrom != nil){
                        self.ref.child("trainers/\(uid)/invite_from").setValue(inviteFrom)
                    }
                }else{
                    self.ref.child("clients/\(uid)/name").setValue(name)
                    self.ref.child("clients/\(uid)/email").setValue(email)
                    self.ref.child("clients/\(uid)/membership_at").setValue(Int64(Date().timeIntervalSince1970))
                    self.ref.child("clients/\(uid)/membership_num").setValue(0)
                    if(inviteFrom != nil){
                        self.ref.child("clients/\(uid)/invite_from").setValue(inviteFrom)
                    }
                }

                userDefault.set(self.switchTrainer.isOn, forKey: "is_trainer")

                spinnerActivity.hide(animated: true)
                self.performSegue(withIdentifier: "toWelcomePage", sender: self)
            }else{
                spinnerActivity.hide(animated: true)
                Helper.showMessage(target: self, title: "", message: (error?.localizedDescription)!)
            }
        }
    }


    func setTrainerView(isTrainer:Bool) -> Void {
        if isTrainer {
            trainerView.isHidden = false
            noTrainerView.isHidden = true
            scrollView.contentSize = CGSize(width: 0, height: 1290)
        }else{
            trainerView.isHidden = true
            noTrainerView.isHidden = false
            scrollView.contentSize = CGSize(width: 0, height: 808)
        }
    }
    @IBAction func onBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onPressedStartPeriod(_ sender: UITextField) {
        currentField = sender
        sender.inputView = datePicker
    }
    @IBAction func onPressedEndPeriod(_ sender: UITextField) {
        currentField = sender
        sender.inputView = datePicker
    }
    
    //DatePicker
    
    func datePickerValueChanged(sender: UIDatePicker) {
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        //        currentField.text = dateFormatter.string(from: sender.date)
        currentField.text = sender.date.toString()
    }
    
    //Switch
    func valueChanged(sender: SwiftySwitch) {
        if(sender.isOn){
            sender.myColor = sender.dotOffColor
        }else{
            sender.myColor = UIColor.clear
        }
        setTrainerView(isTrainer: switchTrainer.isOn)
    }
    
    @IBAction func onPressedFitnessGoal(_ sender: UIButton) {
        if sender.isSelected {
            sender.isSelected = false
            sender.superview?.backgroundColor = UIColor.init(rgb: 0x4B4C5A)
        }else{
            sender.isSelected = true
            sender.superview?.backgroundColor = UIColor.init(rgb: 0xF5515F)
        }
    }
    
}


