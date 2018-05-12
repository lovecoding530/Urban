//
//  ResultVC.swift
//  Urban
//
//  Created by Kangtle on 8/9/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Segmentio
import Firebase

enum MeasureType: Int {
    case none
    case length
    case weight
    case percent
}

class ResultVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var ref = Database.database().reference()

    @IBOutlet weak var segmentio: Segmentio!

    @IBOutlet weak var globalView: UIView!
    @IBOutlet weak var globalNationalWeightLossLabel: UILabel!
    @IBOutlet weak var globalMeasureLabel: UILabel!
    
    @IBOutlet weak var basicView: UIView!
    @IBOutlet weak var basicTableView: UITableView!
    
    @IBOutlet weak var girthView: UIView!
    @IBOutlet weak var girthTableView: UITableView!
    
    let basicResultKeys = ["Weight", "Height", "Blood_Pressure", "Body_Fat"]
    let girthResultKeys = ["Neck", "Shoulder", "Chest", "Left_Arm", "Right_Arm", "Waist", "Hip", "Left_Thigh", "Right_Thigh", "Left_Calf", "Right_Calf"]
    
    var worldWeightLoss = 0.0
    var lastResultsDic = [String: String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        setupSegmentio()
        
        getResults()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        basicTableView.reloadData()
        girthTableView.reloadData()
    }
    
    func setupSegmentio(){
        var content = [SegmentioItem]()
        let globalItem = SegmentioItem(
            title: "GLOBAL",
            image: nil
        )
        let basicItem = SegmentioItem(
            title: "BASIC",
            image: nil
        )
        let girthItem = SegmentioItem(
            title: "GIRTH",
            image: nil
        )
        content.append(globalItem)
        content.append(basicItem)
        content.append(girthItem)
        
        let option = SegmentioOptions(
            backgroundColor: .clear,
            maxVisibleItems: 3,
            scrollEnabled: false,
            indicatorOptions: SegmentioIndicatorOptions(
                type: .bottom,
                ratio: 0.3,
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
                self.globalView.isHidden = false
                self.basicView.isHidden = true
                self.girthView.isHidden = true
            case 1:
                self.globalView.isHidden = true
                self.basicView.isHidden = false
                self.girthView.isHidden = true
            case 2:
                self.globalView.isHidden = true
                self.basicView.isHidden = true
                self.girthView.isHidden = false
            default: break
                
            }
        }
        segmentio.selectedSegmentioIndex = 0
    }
    
    func getResults() {
        let uid = Auth.auth().currentUser?.uid ?? ""
        
        let resultsRef = ref.child("results")
        let worldLossRef = resultsRef.child("world_weight_loss")
        let lastResultsRef = resultsRef.child("\(uid)/last_result")
        
        worldLossRef.observe(.value, with: {(snapshot) in
            self.worldWeightLoss = snapshot.value as? Double ?? 0.0
            self.globalNationalWeightLossLabel.text = Int(self.worldWeightLoss).formattedNumber()
        })
        lastResultsRef.observe(.value, with: {(snapshot) in
            self.lastResultsDic = snapshot.value as? [String:String] ?? [:]
            self.basicTableView.reloadData()
            self.girthTableView.reloadData()
        })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === basicTableView {
            return self.basicResultKeys.count
        }else{
            return self.girthResultKeys.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let key = tableView === basicTableView ? basicResultKeys[indexPath.row] : girthResultKeys[indexPath.row]
        cell.textLabel?.text = key.replacingOccurrences(of: "_", with: " ")

        let value = self.lastResultsDic[key] ?? ""
        let convertedStr = Helper.convertMeasureSystem(key: key, value: value)
        
        cell.detailTextLabel?.text = convertedStr
        
        cell.backgroundColor = UIColor.clear
        return cell
        
    }
    
//    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
//        let cell = tableView.cellForRow(at: indexPath)
//        cell?.backgroundColor = UIColor.init(rgb: 0x2D2E40).withAlphaComponent(0.8)
//        return indexPath
//    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let cell = sender as! UITableViewCell
        let destination = segue.destination as! ResultDetailVC
        destination.key = cell.textLabel?.text?.replacingOccurrences(of: " ", with: "_")
    }

}
