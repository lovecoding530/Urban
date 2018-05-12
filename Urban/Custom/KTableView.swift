//
//  KTableView.swift
//  Urban
//
//  Created by Kangtle on 11/21/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit

class KTableView: UITableViewController {

    var tableData : [String]!
    var selectedData = [String]()
    var dropdownField : UITextField!
    var onSelect:((String)->())? = nil
    
    init(tableData: [String], dropdownField: UITextField) {
        
        super.init(style: .plain)
        
        self.tableData = tableData
        self.dropdownField = dropdownField
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.view.backgroundColor = .clear
        self.tableView.backgroundColor = .clear
        
        if !(self.dropdownField.text?.isEmpty)! {
            selectedData = (self.dropdownField.text?.components(separatedBy: ", "))!
        }
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.tableData.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let text = tableData[indexPath.row]
        
        cell.textLabel?.text = text
        
        if(selectedData.contains(text)){
            cell.accessoryType = .checkmark
        }else{
            cell.accessoryType = .none
        }
        
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)

        let text = tableData[indexPath.row]

        if (cell?.accessoryType == .checkmark) {
            cell?.accessoryType = .none;
            selectedData.remove(at: selectedData.index(of: text)!)
        } else {
            cell?.accessoryType = .checkmark;
            selectedData.append(text)
        }
        
        let convertedStr = selectedData.joined(separator: ", ")
        
        dropdownField.text = convertedStr
    }
}
