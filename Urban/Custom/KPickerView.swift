//
//  KPickerView.swift
//  Urban
//
//  Created by Kangtle on 9/14/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit

class KPickerView: UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate{

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    var pickerData : [String]!
    var pickerTextField : UITextField!
    var onSelect:((String)->())? = nil
    
    init(pickerData: [String], dropdownField: UITextField) {
        super.init(frame: .zero)
        
        self.pickerData = pickerData
        self.pickerTextField = dropdownField
        
        self.delegate = self
        self.dataSource = self
        
        DispatchQueue.main.async(execute: {
            if pickerData.count > 0 {
                self.pickerTextField.text = self.pickerData[0]
                self.pickerTextField.isEnabled = true
            } else {
                self.pickerTextField.text = nil
                self.pickerTextField.isEnabled = false
            }
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func selectRow(withText: String) {
        DispatchQueue.main.async(execute: {
            let selectedIndex = (self.pickerData.contains(withText)) ? self.pickerData.index(of: withText) : 0
            self.pickerTextField.text = self.pickerData[selectedIndex!]
            self.selectRow(selectedIndex!, inComponent: 0, animated: false)
        })
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerTextField.text = pickerData[row]
        if(onSelect != nil) {
            onSelect!(pickerData[row])
        }
    }
    
}
