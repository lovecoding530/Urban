//
//  GymTableViewCell.swift
//  Urban
//
//  Created by Kangtle on 8/9/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit

class GymTableViewCell: UITableViewCell {

    @IBOutlet weak var gymImageView: UIImageView!
    @IBOutlet weak var gymNameLabel: UILabel!
    @IBOutlet weak var gymAddressLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var mapMarker: UIImageView!
    
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
    
    func adjustCell(){
        distanceLabel.sizeToFit()
        mapMarker.center.x = distanceLabel.frame.origin.x - 10.0
    }

}
