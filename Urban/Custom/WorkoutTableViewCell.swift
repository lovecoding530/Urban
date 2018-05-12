//
//  WorkoutTableViewCell.swift
//  Urban
//
//  Created by Kangtle on 8/27/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit

class WorkoutTableViewCell: UITableViewCell {
    
    @IBOutlet weak var workoutImageView: UIImageView!
    @IBOutlet weak var workoutNameLabel: UILabel!
    @IBOutlet weak var gymLabel: UILabel!
    @IBOutlet weak var typeAndLevelLabel: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        workoutImageView.layer.cornerRadius = workoutImageView.frame.width/2
        workoutImageView.clipsToBounds = true
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
