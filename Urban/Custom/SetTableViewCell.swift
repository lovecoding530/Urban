//
//  SetTableViewCell.swift
//  Urban
//
//  Created by Kangtle on 8/15/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit

class SetTableViewCell: UITableViewCell {

    
    @IBOutlet weak var setImageView: UIImageView!
    @IBOutlet weak var setNameLabel: UILabel!
    @IBOutlet weak var setDescriptionLabel: UILabel!
    @IBOutlet weak var setDurationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setImageView.layer.cornerRadius = setImageView.frame.width/2
        setImageView.clipsToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

}
