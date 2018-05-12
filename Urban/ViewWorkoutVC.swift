//
//  ViewWorkoutVC.swift
//  Urban
//
//  Created by Kangtle on 9/7/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import Segmentio
import Cosmos

class ViewWorkoutVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var scrollView: UIScrollView!

    //MARK: - description view
    @IBOutlet weak var descriptionView: UIView!
    @IBOutlet weak var workoutDescriptionLabel: UILabel!
    @IBOutlet weak var workoutDetailView: UIView!
    @IBOutlet weak var workoutSetsTableView: UITableView!
    @IBOutlet weak var workoutImageView: UIImageView!
    @IBOutlet weak var workoutNameLabel: UILabel!
    @IBOutlet weak var segmentio: Segmentio!
    
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var muscleGroupLabel: UILabel!
    @IBOutlet weak var caloriesBurnLabel: UILabel!
    
    //MARK: - feedback view
    @IBOutlet weak var feedbackView: UIView!
    @IBOutlet weak var feedbackTableView: UITableView!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var ratingCosmosView: CosmosView!
    @IBOutlet weak var ratingWrapperView: UIView!
    
    var ref: DatabaseReference!
    let storageRef = Storage.storage().reference()
    var workout: Workout! = nil
    var sets: Array<WorkoutSet> = Array()
    var feedbacks: [Feedback] = []
    var workoutRating: Int? = nil {
        didSet {
            ratingLabel.text = String(format: "%.1f", Double(workoutRating!))
            ratingCosmosView.rating = Double(self.workoutRating!)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSegmentio()
        workoutSetsTableView.delegate = self
        workoutSetsTableView.dataSource = self
        
        ref = Database.database().reference()
        
        let photoRef = storageRef.child(workout.photoUrl)
        workoutImageView.sd_setImage(with: photoRef)
        _ = Helper.insertGradientLayer(target: workoutImageView)
        workoutNameLabel.text = workout.name
        
        typeLabel.text = workout.type ?? ""
        levelLabel.text = workout.level ?? ""
        durationLabel.text = "\(workout.duration ?? 0) min"
        muscleGroupLabel.text = workout.muscleGroup
        caloriesBurnLabel.text = "\(workout.caloriesBurn ?? 0) kcal"

        self.workoutRating = workout.rating
        
        self.setUpDescriptionLayout()
        getSets()
        getFeedbacks()
        // Do any additional setup after loading the view.
    }
    
    func setupSegmentio(){
        var content = [SegmentioItem]()
        let descriptionItem = SegmentioItem(
            title: "DESCRIPTION",
            image: nil
        )
        let feedbackItem = SegmentioItem(
            title: "FEEDBACK",
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
                height: 4,
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
                self.descriptionView.isHidden = false
                self.feedbackView.isHidden = true
                self.setUpDescriptionLayout()
            case 1:
                self.descriptionView.isHidden = true
                self.feedbackView.isHidden = false
                self.setUpFeedbackLayout()
            default:
                break
            }
        }
    }
    
    func getSets(){
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Please wait..."
        
        ref.child("sets/\(workout.id!)").observeSingleEvent(of: .value, with: { (snapshot) in
            if let _sets = snapshot.value as? NSDictionary {
                var index = 0
                
                for (_key, _set) in _sets {
                    index += 1
                    let mSet = WorkoutSet(withDic: _set as! NSDictionary)
                    mSet.id = _key as! String
                    mSet.name = "SET  #\(index)"
                    self.sets.append(mSet)
                }
                
                spinnerActivity.hide(animated: true)
                self.workoutSetsTableView.reloadData()
                if self.workoutSetsTableView.contentSize.height > self.workoutSetsTableView.frame.size.height {
                    self.workoutSetsTableView.frame.size = self.workoutSetsTableView.contentSize
                }
                if !self.descriptionView.isHidden {
                    self.setUpDescriptionLayout()
                }
                self.workout.sets = self.sets
            }else{
                spinnerActivity.hide(animated: true)
            }
        }) { (error) in
            
            print(error.localizedDescription)
            
        }
    }
    
    func getFeedbacks(){
        
        ref.child("feedbacks/\(workout.id!)").observe(.childAdded, with: { (snapshot) in
            if let _feedback = snapshot.value as? [String: Any] {
                
                let mFeedback = Feedback(withDic: _feedback)
                mFeedback.id = snapshot.key
                
                let userRef = self.ref.child("clients/\(mFeedback.clientId ?? "")")
                
                userRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    if let userDic = snapshot.value  as? [String : Any]{
                        mFeedback.client = User(withDic: userDic)
                        self.feedbacks.append(mFeedback)
                        self.feedbackTableView.reloadData()
                        
                        if self.feedbackTableView.contentSize.height > self.feedbackTableView.frame.size.height {
                            self.feedbackTableView.frame.size = self.feedbackTableView.contentSize
                        }
                        if !self.feedbackView.isHidden{
                            self.setUpFeedbackLayout()
                        }
                    }
                })
            }
        })
    }
    
    func setUpDescriptionLayout(){
        self.workoutDescriptionLabel.numberOfLines = 0
        self.workoutDescriptionLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        self.workoutDescriptionLabel.text = workout.description ?? ""
        self.workoutDescriptionLabel.sizeToFit()
        
        self.workoutDetailView.frame.origin.y = self.workoutDescriptionLabel.frame.maxY + 10
        
        self.workoutSetsTableView.frame.origin.y = self.workoutDetailView.frame.maxY + 10
        
        let height = workoutDescriptionLabel.frame.height +
            workoutDetailView.frame.height +
            workoutSetsTableView.frame.height
        
        let frame = CGRect(x: descriptionView.frame.origin.x, y: descriptionView.frame.origin.y, width: descriptionView.frame.width, height: height + 54)
        descriptionView.frame = frame
        descriptionView.layer.cornerRadius = 5
        
        scrollView.contentSize = CGSize(width: 0, height: descriptionView.frame.maxY-54)
    }
    
    func setUpFeedbackLayout(){
        
        self.workoutSetsTableView.frame.origin.y = self.ratingWrapperView.frame.maxY + 10
        
        let height = ratingWrapperView.frame.height + 10 + feedbackTableView.frame.height
        
        let frame = CGRect(x: feedbackView.frame.origin.x, y: feedbackView.frame.origin.y, width: feedbackView.frame.width, height: height + 34)
        feedbackView.frame = frame
        feedbackView.layer.cornerRadius = 5
        
        scrollView.contentSize = CGSize(width: 0, height: feedbackView.frame.maxY-54)
    }
    
 
    //MARK: - Table view delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView === workoutSetsTableView){
            return sets.count
        }else{
            return feedbacks.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === workoutSetsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SetTableViewCell", for: indexPath) as! SetTableViewCell
            
            let set = sets[indexPath.row]
            cell.setNameLabel.text = set.name
            cell.setDescriptionLabel.text = set.description
            cell.setDurationLabel.text = "\(String(set.duration)) min"
            
            let reference = storageRef.child(set.thumbUrl)
            let placeholderImage = UIImage(named: "placeholder_fitness.png")
            cell.setImageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
            
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "FeedbackTableViewCell", for: indexPath) as! FeedbackTableViewCell
            
            let feedback = self.feedbacks[indexPath.row]
            cell.feedbackLabel.text = feedback.feedback
            cell.feedbackLabel.sizeToFit()
            cell.nameAndTimeLabel.text = "\(feedback.client.name ?? ""), \(Helper.timeStr(for: feedback.time))"
            
            let reference = storageRef.child(feedback.client.photoUrl)
            let placeholderImage = UIImage(named: "placeholder_user.png")
            cell.clientImageview.sd_setImage(with: reference, placeholderImage: placeholderImage)
            
            cell.layoutIfNeeded()
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(tableView === feedbackTableView){
            let cell = tableView.dequeueReusableCell(withIdentifier: "FeedbackTableViewCell") as! FeedbackTableViewCell
            cell.feedbackLabel.text = self.feedbacks[indexPath.row].feedback
            cell.feedbackLabel.sizeToFit()
            return CGFloat(cell.height())
        }else{
            return 80.0
        }
    }
    
    //MARK: - IBActions
    
    @IBAction func onBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func onEdit(_ sender: Any) {
        let editWorkoutVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EditWorkoutVC") as! EditWorkoutVC
        editWorkoutVC.editingWorkout = self.workout
        self.navigationController?.pushViewController(editWorkoutVC, animated: true)
    }
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
}
