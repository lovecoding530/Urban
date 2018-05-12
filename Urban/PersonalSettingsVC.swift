//
//  PersonalSettingsVC.swift
//  Urban
//
//  Created by Kangtle on 8/24/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import FirebaseStorage

class PersonalSettingsVC: UIViewController,
                          UIPickerViewDataSource, UIPickerViewDelegate,
                          UITextFieldDelegate,
                          UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameEdit: UITextField!
    @IBOutlet weak var countryEdit: UITextField!
    @IBOutlet weak var cityEdit: UITextField!
    @IBOutlet weak var measurementSystemEdit: UITextField!
    @IBOutlet weak var distanceUnitEdit: UITextField!
    
    var user: User!
    var currentField: UITextField!
    var pickerView: UIPickerView!
    let defaults = UserDefaults.standard
    let measurementSystems:[MeasurementSystem] = [.Imperial, .Metric]
    let distanceUnits = ["Km", "Mile"]
    var userMeasurementSystem: MeasurementSystem!
    var distanceUnit: String!
    let storageRef = Storage.storage().reference()
    var ref = Database.database().reference()

    var imagePicker:UIImagePickerController?=UIImagePickerController()
    
    var isTrainer: Bool!
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toolBar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)

        isTrainer = defaults.bool(forKey: "is_trainer")

        imagePicker?.delegate = self
        
        userImageView.layer.cornerRadius = userImageView.frame.width/2
        userImageView.clipsToBounds = true

        userImageView.image = user.photo

        userNameEdit.text = user.name
        countryEdit.text = user.country
        cityEdit.text = user.city
        
        let systemStr = defaults.string(forKey: "measurement_system") ?? MeasurementSystem.Metric.rawValue
        userMeasurementSystem = MeasurementSystem(rawValue: systemStr)!
        measurementSystemEdit.text = systemStr

        distanceUnit = defaults.string(forKey: "distance_unit") ?? "Km"
        distanceUnitEdit.text = distanceUnit
        
        self.pickerView = UIPickerView()
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
        
        
        if locManager.location != nil && (user.country.isEmpty || user.city.isEmpty) {
            getAddress()
        }
        // Do any additional setup after loading the view.
    }
    
    func getAddress() {
        let geoCoder = CLGeocoder()
        let curLocation = locManager.location
        geoCoder.reverseGeocodeLocation(curLocation!, completionHandler: { (placemarks, error) -> Void in
            
            // Place details
            var placeMark: CLPlacemark!
            placeMark = placemarks?[0]
            if placeMark == nil {
                return
            }
            // Address dictionary
            print(placeMark.addressDictionary as Any)
            
            // City
            if let city = placeMark.addressDictionary!["City"] as? NSString {
                print(city)
                self.cityEdit.text = city as String
            }
            // Country
            if let country = placeMark.addressDictionary!["Country"] as? NSString {
                print(country)
                self.countryEdit.text = country as String
            }
            
            self.savePersonalSettings()
        })
    }
    
    @IBAction func onBack(_ sender: Any) {
        self.performSegueToReturnBack()
    }

    @IBAction func onPressedMeasurement(_ sender: UITextField) {
        currentField = sender
        pickerView.reloadAllComponents()
        sender.inputView = self.pickerView
        pickerView.selectRow(measurementSystems.index(of: userMeasurementSystem)!, inComponent: 0, animated: true)
    }

    @IBAction func onPressedDistanceUnit(_ sender: UITextField) {
        currentField = sender
        pickerView.reloadAllComponents()
        sender.inputView = self.pickerView
        pickerView.selectRow(distanceUnits.index(of: distanceUnit)!, inComponent: 0, animated: true)
    }
    
    //Picker
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if currentField === measurementSystemEdit {
            return measurementSystems.count
        }else{
            return distanceUnits.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if currentField === measurementSystemEdit {
            return measurementSystems[row].rawValue
        }else{
            return distanceUnits[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        if currentField === measurementSystemEdit {
            let systemStr = measurementSystems[row].rawValue
            defaults.set(systemStr, forKey: "measurement_system")
            currentField.text = systemStr
        }else{
            let distanceUnit = distanceUnits[row]
            defaults.set(distanceUnit, forKey: "distance_unit")
            currentField.text = distanceUnit
        }
    }
    
    @IBAction func onPressedUpload(_ sender: Any) {
        //1
        let optionMenu = UIAlertController(title: nil, message: "Open with", preferredStyle: .actionSheet)
        
        // 2
        let galleryAction = UIAlertAction(title: "Photo Gallery", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.imagePicker?.allowsEditing = false
            self.imagePicker?.sourceType = .photoLibrary
            self.present(self.imagePicker!, animated: true, completion: nil)
            
        })
        let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            if(UIImagePickerController.isSourceTypeAvailable(.camera)){
                self.imagePicker?.allowsEditing = false
                self.imagePicker?.sourceType = .camera
                self.imagePicker?.cameraCaptureMode = .photo
                self.present(self.imagePicker!, animated: true, completion: nil)
            }else{
                Helper.showMessage(target: self, title: "", message: "This device is no camera")
            }
        })
        
        //
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        
        
        // 4
        optionMenu.addAction(galleryAction)
        optionMenu.addAction(cameraAction)
        optionMenu.addAction(cancelAction)
        
        // 5
        self.present(optionMenu, animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            ////////////////////
            let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
            spinnerActivity.label.text = "Please wait..."
            ////////////////////
            var type = "JPG"
            if let url = info[UIImagePickerControllerReferenceURL] as? URL {
                type = url.pathExtension
            }
            userImageView.image = image
            let uid = user.id ?? ""
            let uploadUrl = "images/users/\(uid)_\(Int64(Date().timeIntervalSince1970)).\(type)"
            let imagesRef = storageRef.child(uploadUrl)
            _ = imagesRef.putData(UIImageJPEGRepresentation(image, 0.1)!, metadata: nil) { (metadata, error) in
                guard metadata != nil else {
                    // Uh-oh, an error occurred!
                    spinnerActivity.hide(animated: true)
                    return
                }
                // Metadata contains file metadata such as size, content-type, and download URL.
                if self.isTrainer {
                    self.ref.child("trainers/\(uid)/photo_url").setValue(uploadUrl)
                }else{
                    self.ref.child("clients/\(uid)/photo_url").setValue(uploadUrl)
                }
                spinnerActivity.hide(animated: true)
            }
        } else{
            print("Something went wrong")
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onPressedDelete(_ sender: Any) {
        if(user.photoUrl == "" || user.photoUrl == "none") {
            return
        }
        ////////////////////
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Please wait..."
        ////////////////////

        // Create a reference to the file to delete
        let desertRef = storageRef.child(user.photoUrl ?? "")
        
        // Delete the file
        desertRef.delete { error in
            if error != nil {
                // Uh-oh, an error occurred!
//                Helper.showMessage(target: self, title: "", message: (error?.localizedDescription)!)
            }
            self.userImageView.image = UIImage.init(named: "placeholder_user")
            self.ref.child("clients/\(self.user.id ?? "")/photo_url").setValue("none")
            spinnerActivity.hide(animated: true)
        }
    }
    @IBAction func editingDidEndName(_ sender: Any) {
        savePersonalSettings()
    }
    
    func savePersonalSettings(){
        let name = userNameEdit.text ?? ""
        let country = countryEdit.text ?? ""
        let city = cityEdit.text ?? ""
        if name.isEmpty {
            Helper.showMessage(target: self, title: "", message: "Enter user name")
            return
        }
        if country.isEmpty || city.isEmpty {
            Helper.showMessage(target: self, title: "", message: "Enter country and city you live in")
            return
        }
        
        let updatingDic = [
            "name" : name,
            "country" : country,
            "city" : city
        ]
        
        let uid = user.id ?? ""
        if self.isTrainer {
            self.ref.child("trainers/\(uid)").updateChildValues(updatingDic)
        }else{
            self.ref.child("clients/\(uid)").updateChildValues(updatingDic)
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
