//
//  EditWorkoutVC.swift
//  Urban
//
//  Created by Kangtle on 8/28/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Segmentio
import Firebase
import FirebaseStorage
import BGTableViewRowActionWithImage
import GoogleMaps

class EditWorkoutVC: UIViewController,
                     UIImagePickerControllerDelegate, UINavigationControllerDelegate,
                     UITextViewDelegate,
                     UITableViewDelegate, UITableViewDataSource,
                     GMSMapViewDelegate
{

    @IBOutlet weak var segmentio: Segmentio!
    @IBOutlet weak var basicInfoScrollView: UIScrollView!
    @IBOutlet weak var setsView: UIView!
    @IBOutlet weak var workoutDescTextView: UITextView!
    @IBOutlet weak var typeField: UITextField!
    @IBOutlet weak var levelField: UITextField!
    @IBOutlet weak var durationField: UITextField!
    @IBOutlet weak var muscleGroupField: UITextField!
    @IBOutlet weak var caloriesBurnField: UITextField!
    @IBOutlet weak var workoutPreviewImageView: UIImageView!
    @IBOutlet weak var workoutNameField: UITextField!
    @IBOutlet weak var setsTable: UITableView!
    @IBOutlet weak var mapView: GMSMapView!
    
//    var pickerView: UIPickerView!
    let workoutTypes = ["Cardio", "Strength", "Flexibility"]
    let workoutLevels = ["Beginner", "Intermediate", "Advanced"]
    let workoutMuscleGroups = ["Chest", "Arms", "Back", "Glutes", "Legs", "Core"]
    var currentField: UITextField!

    var imagePicker:UIImagePickerController?=UIImagePickerController()

    let textViewPlaceholder = "Enter description of workout"
    let textViewPlaceholderColor = UIColor.lightGray
    let textViewTextColor = UIColor.white
    
    var editingWorkout: Workout? = nil
    var isNewWorkout = false
    var isEditedPreview = false
    var isEditedSet = false
    
    let storageRef = Storage.storage().reference()
    var ref = Database.database().reference()
    
    var fromTab = true

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true

        if fromTab {
            self.navigationItem.leftBarButtonItem = nil
        }
        
        self.typeField.delegate = self
        self.levelField.loadDropdownData(data: workoutLevels)
        self.muscleGroupField.delegate = self
        
        isNewWorkout = editingWorkout == nil ? true : false
        if isNewWorkout {
            editingWorkout = Workout()
            self.navigationItem.title = "ADD A WORKOUT"
            
        }else{
            setEditingValues()
            getSets()
            self.showGym()
            self.navigationItem.title = editingWorkout?.name.uppercased()
        }
        editingWorkout?.sets = [WorkoutSet]()
        
        setupSegmentio()
        
        self.imagePicker?.delegate = self
        
        workoutPreviewImageView.layer.cornerRadius = 5
        workoutPreviewImageView.clipsToBounds = true

        workoutDescTextView.delegate = self
        if isNewWorkout {
            workoutDescTextView.text = textViewPlaceholder
            workoutDescTextView.textColor = textViewPlaceholderColor
        }
        // Do any additional setup after loading the view.
    }

    func clearAllFields(){
        self.workoutPreviewImageView.image = nil
        self.mapView.isHidden = true
        self.workoutNameField.text = nil
        self.workoutDescTextView.text = nil
        self.caloriesBurnField.text = nil
        self.editingWorkout = Workout()
        self.editingWorkout?.sets = [WorkoutSet]()
        self.setsTable.reloadData()
        self.setWorkoutDuration()
    }
    
    func setupSegmentio(){
        var content = [SegmentioItem]()
        let basicItem = SegmentioItem(
            title: "GYMFORMATION",
            image: nil
        )
        let setsItem = SegmentioItem(
            title: "SETS",
            image: nil
        )
        content.append(basicItem)
        content.append(setsItem)
        
        let option = SegmentioOptions(
            backgroundColor: .clear,
            maxVisibleItems: 3,
            scrollEnabled: false,
            indicatorOptions: SegmentioIndicatorOptions(
                type: .bottom,
                ratio: 0.2,
                height: 3,
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
                highlightedState: SegmentioState(
                    backgroundColor: .clear,
                    titleFont: UIFont(name: "Helvetica-Bold", size: UIFont.smallSystemFontSize)!,
                    titleTextColor: UIColor.init(rgb: 0xF5515F)
                )
            ),
            animationDuration: 0.1
        )
        
        segmentio.setup(
            content: content,
            style: .onlyLabel,
            options: option
        )
        
        segmentio.valueDidChange = { segmentio, segmentIndex in
            print("Selected item: ", segmentIndex)
            switch segmentIndex {
            case 0:
                self.basicInfoScrollView.isHidden = false
                self.setsView.isHidden = true
                self.setWorkoutDuration()
            case 1:
                self.basicInfoScrollView.isHidden = true
                self.setsView.isHidden = false
            default: break
                
            }
        }
        segmentio.selectedSegmentioIndex = 0
    }
    
    func showGym() {
        if(editingWorkout?.gym != nil){
            self.mapView.isHidden = false
            
            let camera = GMSCameraPosition.camera(withLatitude: (editingWorkout?.gym.location.latitude)!,
                                                  longitude: (editingWorkout?.gym.location.longitude)!, zoom: 16.0)
            mapView.camera = camera

            let marker = GMSMarker()
            marker.position = (editingWorkout?.gym.location)!
            marker.icon = UIImage(named: "circle_marker")
            marker.title = editingWorkout?.gym.name
            marker.snippet = editingWorkout?.gym.address
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
            marker.map = mapView

        }
    }
    
    func getSets(){
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Please wait..."
        
        ref.child("sets/\(editingWorkout?.id ?? "")").observeSingleEvent(of: .value, with: { (snapshot) in
            if let _sets = snapshot.value as? NSDictionary {

                for (_key, _set) in _sets {
                    let mSet = WorkoutSet(withDic: _set as! NSDictionary)
                    mSet.id = _key as! String
                    self.editingWorkout?.sets.append(mSet)
                }
                
                spinnerActivity.hide(animated: true)
                self.setWorkoutDuration()
                self.setsTable.reloadData()
            }else{
                spinnerActivity.hide(animated: true)
            }
        }) { (error) in
            
            print(error.localizedDescription)
            
        }
    }
    
    func setEditingValues() {
        let reference = self.storageRef.child((editingWorkout?.photoUrl)!)
        self.workoutPreviewImageView.sd_setImage(with: reference)

        self.workoutNameField.text = editingWorkout?.name
        self.workoutDescTextView.text = editingWorkout?.description

        self.typeField.text = editingWorkout?.type
        self.levelField.setTextWithPickerView(text: editingWorkout?.level)
        self.muscleGroupField.text = editingWorkout?.muscleGroup
        
        self.caloriesBurnField.text = String(editingWorkout?.caloriesBurn ?? 0)
    }
    
    func setWorkoutDuration() {
        var duration = 0
        for set in (editingWorkout?.sets)! {
            duration += set.duration
        }
        
        durationField.text = String(duration)
    }
    
    @IBAction func onBack(_ sender: Any) {
        self.performSegueToReturnBack()
    }
    @IBAction func onDone(_ sender: Any) {
        editingWorkout?.name = workoutNameField.text
        editingWorkout?.description = workoutDescTextView.text
        editingWorkout?.type = typeField.text
        editingWorkout?.level = levelField.text
        editingWorkout?.duration = Int(durationField.text!) ?? 0
        editingWorkout?.muscleGroup = muscleGroupField.text
        editingWorkout?.caloriesBurn = Int(caloriesBurnField.text!) ?? 0
        if workoutPreviewImageView.image == nil {
            Helper.showMessage(target: self, title: "", message: "Add a preview of workout")
            return
        }
        if editingWorkout?.gym == nil {
            Helper.showMessage(target: self, title: "", message: "Choose a urban gym")
            return
        }
        if (editingWorkout?.name.isEmpty)! {
            Helper.showMessage(target: self, title: "", message: "Enter name of workout")
            return
        }
        if (editingWorkout?.description?.isEmpty)! {
            Helper.showMessage(target: self, title: "", message: "Enter description of workout")
            return
        }
        if (editingWorkout?.type?.isEmpty)! {
            Helper.showMessage(target: self, title: "", message: "Choose type of workout")
            return
        }
        if (editingWorkout?.level?.isEmpty)! {
            Helper.showMessage(target: self, title: "", message: "Choose level of workout")
            return
        }
        if (editingWorkout?.muscleGroup?.isEmpty)! {
            Helper.showMessage(target: self, title: "", message: "Choose muscle group of workout")
            return
        }
        
//        if editingWorkout?.caloriesBurn == 0 {
//            Helper.showMessage(target: self, title: "", message: "Enter calories burnt of workout")
//            return
//        }
//        
        
        saveEditingWorkout()
        
        if fromTab {
            self.tabBarController?.selectedIndex = 0
            self.clearAllFields()
        }
    }
    
    @IBAction func onTappedPreview(_ sender: Any) {
        print("tapped preview")
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
    
    @IBAction func onTappedChooseGym(_ sender: Any) {
        print("tapped choose gym")
        if locManager.location != nil {
//            self.performSegue(withIdentifier: "TrainerChooseGymVC", sender: self)
            let chooseVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TrainerChooseGymVC") as! TrainerChooseGymVC
            chooseVC.onDoneBlock = {(selectedGym) in
                chooseVC.performSegueToReturnBack()
                self.editingWorkout?.gym = selectedGym
                self.showGym()
                print("onDoneBlock", selectedGym.address)
            }
            chooseVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(chooseVC, animated: true)
//            self.present(chooseVC, animated: true, completion: nil)
        }else{
            Helper.showMessage(target: self, title: "", message: "Can't find your location")
        }
    }
    
    @IBAction func onPressedAddSet(_ sender: Any) {
        
        let editWorkoutSetVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EditWorkoutSetVC") as! EditWorkoutSetVC
        editWorkoutSetVC.onDoneBlock = onDoneSetEdit
        self.navigationController?.pushViewController(editWorkoutSetVC, animated: true)

    }
    
    //MARK: image picker
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            isEditedPreview = true
            workoutPreviewImageView.image = image
            self.editingWorkout?.photo =  image
        } else {
            print("Something went wrong")
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    //MARK: textview
    
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
    
    //MARK: TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.editingWorkout!.sets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SetTableViewCell", for: indexPath) as! SetTableViewCell
        
        let set = editingWorkout?.sets[indexPath.row]
        cell.setNameLabel.text = "SET #\(indexPath.row + 1)"
        cell.setImageView.image = set?.thumb
        cell.setDescriptionLabel.text = set?.description
        cell.setDurationLabel.text = "\(set?.duration ?? 0) min"
        
        let reference = storageRef.child((set?.thumbUrl)!)
        let placeholderImage = UIImage(named: "placeholder_fitness.png")
        cell.setImageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
        
        cell.backgroundColor = .clear
        return cell
    }
    
//    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
//        let cell = tableView.cellForRow(at: indexPath)
//        cell?.backgroundColor = UIColor.init(rgb: 0x2D2E40).withAlphaComponent(0.8)
//        return indexPath
//    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = BGTableViewRowActionWithImage.rowAction(with: .destructive,
                                                             title: "Delete",
                                                             backgroundColor: UIColor(rgb: 0xF5515F),
                                                             image: UIImage(named: "icon_delete"),
                                                             forCellHeight: 80){(action, indexPath) in
            self.isEditedSet = true
            self.editingWorkout?.sets.remove(at: (indexPath?.row)!)
            tableView.reloadData()
        }
        
        let edit = BGTableViewRowActionWithImage.rowAction(with: .default,
                                                           title: "Edit ",
                                                           backgroundColor: UIColor(rgb: 0xF5515F),
                                                           image: UIImage(named: "icon_edit"),
                                                           forCellHeight: 80){(action, indexPath) in
            self.isEditedSet = true
            let editWorkoutSetVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EditWorkoutSetVC") as! EditWorkoutSetVC
            editWorkoutSetVC.editingSet = self.editingWorkout?.sets[(indexPath?.row)!]
            editWorkoutSetVC.onDoneBlock = self.onDoneSetEdit
            self.navigationController?.pushViewController(editWorkoutSetVC, animated: true)
                                                            
        }
        
        return [edit!, delete!]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.isEditedSet = true
        let editWorkoutSetVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EditWorkoutSetVC") as! EditWorkoutSetVC
        editWorkoutSetVC.editingSet = self.editingWorkout?.sets[indexPath.row]
        editWorkoutSetVC.onDoneBlock = self.onDoneSetEdit
        self.navigationController?.pushViewController(editWorkoutSetVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return tableView.isEditing ? .none : .delete
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        self.isEditedSet = true
        let temp = editingWorkout?.sets[sourceIndexPath.row]
        editingWorkout?.sets[sourceIndexPath.row] = (editingWorkout?.sets[destinationIndexPath.row])!
        editingWorkout?.sets[destinationIndexPath.row] = temp!
        tableView.reloadData()
    }
    
    @IBAction func longPressedSetsTable(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began{
            self.setsTable.setEditing(!self.setsTable.isEditing, animated: true)
        }
    }

    func onDoneSetEdit(set: WorkoutSet, isNew: Bool){
        self.isEditedSet = true

        print( "on done set edit" )
        if isNew {
            self.editingWorkout?.sets.append(set)
        }
        self.setsTable.reloadData()
    }
    
    func saveEditingWorkout() {
        ////////////////////
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Uploading..."
        ////////////////////
        
        let group = DispatchGroup()
        
        let timestamp = Int64(Date().timeIntervalSince1970)
        var previewUploadUrl = editingWorkout?.photoUrl
        if isNewWorkout || isEditedPreview {
            group.enter()
            previewUploadUrl = "images/workouts/workout_\(timestamp).JPG"
            let uploadRef = storageRef.child(previewUploadUrl!)
            uploadRef.putData(UIImageJPEGRepresentation(workoutPreviewImageView.image!, 0.1)!, metadata: nil) { (metadata, error) in
                guard metadata != nil else {
                    // Uh-oh, an error occurred!
                    Helper.showMessage(target: self, title: "", message: (error?.localizedDescription)!)
                    return
                }
                group.leave()
            }
        }
        
        let uid = Auth.auth().currentUser?.uid ?? ""
        let gymId = editingWorkout?.gym.id ?? ""
        let workoutDic: [String: Any] = [
            "name" : editingWorkout?.name ?? "",
            "description" : editingWorkout?.description ?? "",
            "type" : editingWorkout?.type ?? "",
            "level" : editingWorkout?.level ?? "",
            "duration" : editingWorkout?.duration ?? 0,
            "muscle_group" : editingWorkout?.muscleGroup ?? "",
            "calories_burn" : editingWorkout?.caloriesBurn ?? 0,
            "gym_id" : gymId,
            "trainer_id" : uid,
            "gym_trainer" : "\(gymId)_\(uid)",
            "preview_photo_url" : previewUploadUrl ?? ""
        ]
        
        var workoutRef : DatabaseReference
        
        if isNewWorkout {
            workoutRef = self.ref.child("workouts").childByAutoId()
        }else{
            let workoutId = self.editingWorkout?.id ?? ""
            workoutRef = self.ref.child("workouts/\(workoutId)")
        }
        workoutRef.updateChildValues(workoutDic)

        //gym_trainers
        self.ref.child("gym_trainers/\(gymId)/\(uid)").setValue(true)
        
        //trainer_gyms
        self.ref.child("trainer_gyms/\(uid)/\(gymId)").setValue(true)
        
        
        if isNewWorkout || isEditedSet {
            let workoutKey = workoutRef.key
            let setRef = ref.child("sets/\(workoutKey)")
            var setAllDic = [String: Any]()
            for workoutSet in (editingWorkout?.sets)! {
                let autoId = setRef.childByAutoId().key
                
                let setDic : [String : Any] = [
                    "description" : workoutSet.description ?? "",
                    "duration" : workoutSet.duration ?? 0,
                    "reps" : workoutSet.reps ?? 0,
                    "video_url" : workoutSet.videoUrl ?? "",
                    "thumb_image_url" : workoutSet.thumbUrl ?? "",
                ]
                setAllDic[autoId] = setDic
            }
            setRef.setValue(setAllDic)
        }
        
        group.notify(queue: .main){
            spinnerActivity.hide(animated: true)
            self.performSegueToReturnBack()
        }
    }
    
    // MARK: - Map View
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        self.onTappedChooseGym(self)
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

extension EditWorkoutVC: UITextFieldDelegate{
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if textField === typeField {
            loadTableData(textField: textField, data: workoutTypes)
        }else if textField === muscleGroupField {
            loadTableData(textField: textField, data: workoutMuscleGroups)
        }
    }
    
    func loadTableData(textField: UITextField!, data: [String], onSelect: ((String)->())? = nil) {
        let tableViewController = KTableView(tableData: data, dropdownField: textField)
        tableViewController.onSelect = onSelect
        textField.inputView = tableViewController.tableView
        addChildViewController(tableViewController)
    }
}
