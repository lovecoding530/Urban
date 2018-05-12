//
//  TrainerProfileVC.swift
//  Urban
//
//  Created by Kangtle on 9/21/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Segmentio
import CoreLocation
import Firebase
import FirebaseStorage
import Cosmos

class TrainerProfileVC: UIViewController,
                        UIImagePickerControllerDelegate, UINavigationControllerDelegate,
                        UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var trainerProfileImageView: UIImageView!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var segmentio: Segmentio!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var workoutORvideoView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var overviewField: UITextView!
    @IBOutlet weak var locationField: UITextField!
    @IBOutlet weak var areasOfExperienceField: UITextView!
    @IBOutlet weak var professionalField: UITextView!
    @IBOutlet weak var scrollview: UIScrollView!
    
    @IBOutlet weak var doneBtn: UIBarButtonItem!
    @IBOutlet weak var contactBtn: UIButton!
    
    var isTrainer = false
    let userDefaults = UserDefaults.standard

    let storageRef = Storage.storage().reference()
    var ref = Database.database().reference()
    
    var imagePicker:UIImagePickerController?=UIImagePickerController()

    var trainerId: String!
    var mTrainer: Trainer!
    var workouts: Array<Workout> = Array()
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        isTrainer = userDefaults.bool(forKey: "is_trainer")
        if isTrainer {
            scrollview.contentSize = CGSize(width: 0, height: 835)
            contactBtn.isHidden = true
        }else{
            scrollview.contentSize = CGSize(width: 0, height: 890)
            contactBtn.isHidden = false
        }
        self.setEditable(isEnabled: isTrainer)
        
        self.toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        self.toolbar.backgroundColor = .clear
        
        setupSegmentio()
        imagePicker?.delegate = self
        
        _ = Helper.insertGradientLayer(target: trainerProfileImageView)
        
        
        getTrainer()
        getWorkouts()
        if locManager.location != nil && isTrainer {
            getAddress()
        }

        // Do any additional setup after loading the view.
    }

    func setEditable(isEnabled: Bool){
        if !isEnabled {
            toolbar.items?.removeLast()
        }
        
        self.nameField.isEnabled = isEnabled
        self.titleField.isEnabled = isEnabled
        self.overviewField.isEditable = isEnabled
        self.locationField.isEnabled = isEnabled
        self.areasOfExperienceField.isEditable = isEnabled
        self.professionalField.isEditable = isEnabled
        self.trainerProfileImageView.isUserInteractionEnabled = isEnabled
    }
    
    func setupSegmentio(){
        var content = [SegmentioItem]()
        let descriptionItem = SegmentioItem(
            title: "INFO",
            image: nil
        )
        let feedbackItem = SegmentioItem(
            title: "WORKOUTS",
            image: nil
        )
        content.append(descriptionItem)
        content.append(feedbackItem)
        
        let option = SegmentioOptions(
            backgroundColor: .white,
            maxVisibleItems: 3,
            scrollEnabled: false,
            indicatorOptions: SegmentioIndicatorOptions(
                type: .bottom,
                ratio: 0.3,
                height: 2,
                color: UIColor.init(rgb: 0xF5515F)
            ),
            horizontalSeparatorOptions: SegmentioHorizontalSeparatorOptions(
                type: SegmentioHorizontalSeparatorType.topAndBottom, // Top, Bottom, TopAndBottom
                height: 0,
                color: .gray
            ),
            verticalSeparatorOptions: nil,
            imageContentMode: .center,
            labelTextAlignment: .center,
            labelTextNumberOfLines: 1,
            segmentStates: SegmentioStates(
                defaultState: SegmentioState(
                    backgroundColor: .clear,
                    titleFont: UIFont(name: "Helvetica-Bold", size: UIFont.smallSystemFontSize)!,
                    titleTextColor: .lightGray
                ),
                selectedState: SegmentioState(
                    backgroundColor: .clear,
                    titleFont: UIFont(name: "Helvetica-Bold", size: UIFont.smallSystemFontSize)!,
                    titleTextColor: UIColor.init(rgb: 0xF5515F)
                ),
                highlightedState: SegmentioState()
            ),
            animationDuration: 0.1
        )
        
        segmentio.setup(
            content: content,
            style: .onlyLabel,
            options: option
        )
        
        segmentio.selectedSegmentioIndex = 0
        
        segmentio.valueDidChange = { segmentio, segmentIndex in
            print("Selected item: ", segmentIndex)
            switch segmentIndex {
            case 0:
                self.infoView.isHidden = false
                self.workoutORvideoView.isHidden = true
            case 1:
                self.infoView.isHidden = true
                self.workoutORvideoView.isHidden = false
            default:
                break
            }
            
        }
    }
    
    func getTrainer(){
        let uid = trainerId ?? ""
        let trainerRef = self.ref.child("trainers/\(uid)")
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Please wait..."
        trainerRef.observeSingleEvent(of: .value, with: { snapshot in
            spinnerActivity.hide(animated: true)
            guard let trainerDic = snapshot.value as? NSDictionary else {return}
            
            self.mTrainer = Trainer(withDic: trainerDic)
            self.mTrainer.id = self.trainerId ?? ""
            
            self.nameField.text = self.mTrainer.name ?? ""
            self.titleField.text = self.mTrainer.title ?? ""
            self.ratingView.rating = Double(self.mTrainer.rating ?? 0)
            self.overviewField.text = self.mTrainer.overview ?? ""
            self.locationField.text = "\(self.mTrainer.city ?? ""), \(self.mTrainer.country ?? "")"
            self.areasOfExperienceField.text = self.mTrainer.areas ?? ""
            self.professionalField.text = self.mTrainer.professional ?? ""
            
            let reference = self.storageRef.child(self.mTrainer.photoUrl ?? "")
            self.trainerProfileImageView.sd_setImage(with: reference, placeholderImage: nil){(photo, error, _, _) in
                if photo == nil{
                    self.mTrainer.photo = UIImage(named: "placeholder_user")
                }else{
                    self.mTrainer.photo = photo
                }
            }
        })
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
            guard let city = placeMark.addressDictionary!["City"] as? NSString else {return}
            // Country
            guard let country = placeMark.addressDictionary!["Country"] as? NSString else {return}
            
            let address = "\(city), \(country)"
            self.locationField.text = address
        })
    }

    func getWorkouts(){
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Please wait..."
        
        let uid = trainerId ?? ""
        let workoutRef = self.ref.child("workouts").queryOrdered(byChild: "trainer_id").queryEqual(toValue: uid)
        
        workoutRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let _workouts = snapshot.value as? NSDictionary {
                let group = DispatchGroup()
                for (_key, _workout) in _workouts {
                    let mWorkout = Workout(withDic: _workout as! NSDictionary)
                    mWorkout.id = _key as! String
                    
                    self.workouts.append(mWorkout)
                    
                    group.enter()
                    let trainerId = (_workout as! NSDictionary)["trainer_id"] as! String
                    self.ref.child("trainers/\(trainerId)").observeSingleEvent(of: .value, with: { (snapshot) in
                        let _trainer = snapshot.value as! NSDictionary
                        let mTrainer = Trainer.init(withDic: _trainer)
                        mTrainer.id = trainerId
                        mWorkout.trainer = mTrainer
                        group.leave()
                    })
                }
                group.notify(queue: .main) {
                    print("All callbacks are completed")
                    spinnerActivity.hide(animated: true)
                    self.collectionView.reloadData()
                }
            }else{
                spinnerActivity.hide(animated: true)
            }
        })
    }

    @IBAction func onBack(_ sender: Any) {
        self.performSegueToReturnBack()
    }
    @IBAction func onDone(_ sender: Any) {
        let uid = trainerId ?? ""
        let name = nameField.text ?? ""
        let title = titleField.text ?? ""
        let location = locationField.text ?? ""
        let overview = overviewField.text ?? ""
        let areas = areasOfExperienceField.text ?? ""
        let professional = professionalField.text ?? ""
        let country = location.components(separatedBy: ", ")[1]
        let city = location.components(separatedBy: ", ")[0]
        
        
        let trainerDic = [
            "name": name,
            "title": title,
            "country": country,
            "city": city,
            "overview": overview,
            "areas": areas,
            "professional": professional
        ]
        
        self.ref.child("trainers/\(uid)").updateChildValues(trainerDic)

        self.performSegueToReturnBack()
    }
    @IBAction func onPressedContact(_ sender: Any) {
        let chatVC = ChatVC()
        let channel = ChatChannel.init(channelId: "\(Auth.auth().currentUser?.uid ?? "")_\(trainerId ?? "")")
        let opponent = Opponent.init(id: mTrainer.id, name: mTrainer.name, photoUrl: mTrainer.photoUrl, photo: mTrainer.photo)
        channel.opponent = opponent
        chatVC.channel = channel
        let chatNavigationController = UINavigationController(rootViewController: chatVC)
        present(chatNavigationController, animated: true, completion: nil)

    }
    @IBAction func onTappedProfileImage(_ sender: Any) {
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
            trainerProfileImageView.image = image
            let uid = trainerId ?? ""
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
    
    
    //MARK: CollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return workouts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WorkoutCollectionCell", for: indexPath) as! WorkoutCollectionCell
        
        let workout = self.workouts[indexPath.row]
        
        cell.workoutNameLabel.text = workout.name
        cell.gradientLayer = Helper.insertGradientLayer(target: cell.workoutImageView)
        
        let reference = storageRef.child(workout.photoUrl)
        let placeholderImage = UIImage(named: "placeholder_fitness.png")
        cell.workoutImageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width/3, height: collectionView.frame.width/3)
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
