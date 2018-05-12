//
//  WorkoutHistoryTableCell.swift
//  Urban
//
//  Created by Kangtle on 8/16/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit

class WorkoutHistoryTableCell: UITableViewCell {
    
    @IBOutlet weak var gymImageView: UIImageView!
    @IBOutlet weak var gymNameLabel: UILabel!
    @IBOutlet weak var workoutNameLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        gymImageView.layer.cornerRadius = gymImageView.frame.width/2
        gymImageView.clipsToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
