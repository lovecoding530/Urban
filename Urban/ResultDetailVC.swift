//
//  ResultDetailVC.swift
//  Urban
//
//  Created by Kangtle on 8/21/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase

class ResultDetailVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {

    struct DetailResult {
        var timestamp: Int64
        var date: Date
        var value: String
    }
    
    var ref = Database.database().reference()

    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addBtn: UIButton!
    @IBOutlet weak var addingView: UIView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var detailTable: UITableView!
    @IBOutlet weak var addingViewToolbar: UIToolbar!
    
    var key: String!
    var pickerData: [[String]] = []
    var detailResults = [DetailResult]()

    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        toolBar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        let title = key.replacingOccurrences(of: "_", with: " ").uppercased()
        titleLabel.text = title
        
        addBtn.setTitle("ADD \(title)", for: .normal)
        addingView.isHidden = true
        
        getDetailResults()
        setupPicker()
    }

    func getDetailResults() {
        let uid = Auth.auth().currentUser?.uid ?? ""
        let resultRef = ref.child("results/\(uid)/detail_result/\(key ?? "")").queryOrderedByKey()

        resultRef.observe(.value, with: {(snapshot) in
            let allDetailsDic = snapshot.value as? [String: Any] ?? [:]

            self.detailResults.removeAll()

            for (key, value) in allDetailsDic {

                let timestamp = Int64(key)
                let value = value as! String
                let detailResult = DetailResult(timestamp: timestamp!, date: Date(timeIntervalSince1970: TimeInterval(timestamp!)), value: value)
                
                self.detailResults.append(detailResult)
            }

            self.detailResults.sort{$0.timestamp > $1.timestamp}
            
            self.detailTable.reloadData()
            
            //for picker view
            
            if let lastResult = self.detailResults.first {
                var valueArr:[String]
                if self.key == "Blood_Pressure"{
                    valueArr = (lastResult.value.components(separatedBy: "/"))
                }else{
                    valueArr = (lastResult.value.components(separatedBy: "."))
                }
                self.pickerView.selectRow(Int(valueArr[0])!, inComponent: 1, animated: false)
                self.pickerView.selectRow(Int(valueArr[1])!, inComponent: 2, animated: false)
            }
        })
    }
    
    func setupPicker() {
        addingViewToolbar.setBackgroundImage(UIImage(named: "bg_toolbar"), forToolbarPosition: .any, barMetrics: .default)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM YYYY"
        
        var dates = [String]()
        let startDate = Calendar.current.date(byAdding: .day, value: -100, to: Date())
        for day in 0...200 {
            let date = Calendar.current.date(byAdding: .day, value: day, to: startDate!)
            let dateString = dateFormatter.string(from: date!)
            dates.append(dateString)
        }
        pickerData.append(dates)
        
        var firstValues = [String]()
        for val in 1...250 {
            firstValues.append(String(val))
        }
        pickerData.append(firstValues)
        
        var secondValues = [String]()
        if self.key == "Blood_Pressure" {
            for val in 1...150 {
                secondValues.append(String(val))
            }
        }else{
            for val in 0...9 {
                secondValues.append(String(describing: Double(val)/10))
            }
        }
        pickerData.append(secondValues)
        
        pickerView.reloadAllComponents()
        
        pickerView.selectRow(100, inComponent: 0, animated: false)
    }
    
    @IBAction func onBack(_ sender: Any) {
        self.performSegueToReturnBack()
    }
    
    @IBAction func onReset(_ sender: Any) {
        let alert = UIAlertController(title: "URBAN", message: "Are you sure to reset results?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
        {
            (result : UIAlertAction) -> Void in

            let uid = Auth.auth().currentUser?.uid ?? ""
            let resultRef = self.ref.child("results/\(uid)/detail_result/\(self.key ?? "")")
            resultRef.removeValue()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default)

        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onPressedCancelAdding(_ sender: Any) {
        addingView.isHidden = true
    }

    @IBAction func onPressedDoneAdding(_ sender: Any) {
        let dateIndex = pickerView.selectedRow(inComponent: 0)
        let firstIndex = pickerView.selectedRow(inComponent: 1)
        let secondIndex = pickerView.selectedRow(inComponent: 2)

        let startDate = Calendar.current.date(byAdding: .day, value: -100, to: Date())
        let selectedDate = Calendar.current.date(byAdding: .day, value: dateIndex, to: startDate!)
        let timestamp = Int64((selectedDate?.timeIntervalSince1970)!)
        var valueStr = ""
        if key == "Blood_Pressure" {
            valueStr = "\(String(firstIndex+1))/\(String(secondIndex+1))"
        }else{
            valueStr = "\(String(Double(firstIndex + 1) + Double(secondIndex)/10))"
        }
        
        let uid = Auth.auth().currentUser?.uid ?? ""

        let resultRef = ref.child("results/\(uid)/detail_result/\(key ?? "")/\(timestamp)")
        let lastResultRef = ref.child("results/\(uid)/last_result/\(key ?? "")/")

        //world weight loss
        if key == "Weight" {
            lastResultRef.observeSingleEvent(of: .value, with: { snapshot in
                //user result
                resultRef.setValue(valueStr)
                lastResultRef.setValue(valueStr)

                guard let lastWeight = snapshot.value as? String else { return }

                let worldLossRef = self.ref.child("results/world_weight_loss")
                
                worldLossRef.observeSingleEvent(of: .value, with: {(snapshot) in
                    let worldWeightLoss = snapshot.value as? Double ?? 0.0
                    
                    let myLoss = Double(lastWeight)! - Double(valueStr)!
                    
                    worldLossRef.setValue(worldWeightLoss + myLoss)
                })
            })
        }else{
            //user result
            resultRef.setValue(valueStr)
            lastResultRef.setValue(valueStr)
        }
        
        addingView.isHidden = true
    }
    @IBAction func onPressedAdd(_ sender: Any) {
        addingView.isHidden = false
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData[component].count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[component][row]
    }
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if component == 0 {
            return pickerView.frame.width * 0.45
        }else if component == 1 {
            return pickerView.frame.width * 0.27
        }else{
            return pickerView.frame.width * 0.28
        }
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return detailResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let detailResult = detailResults[indexPath.row]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM YYYY"
        
        cell.textLabel?.text = dateFormatter.string(from: detailResult.date)
        cell.detailTextLabel?.text = Helper.convertMeasureSystem(key: self.key, value: detailResult.value)
        cell.backgroundColor = UIColor.clear
        return cell
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
