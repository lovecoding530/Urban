//
//  VideoTableViewCell.swift
//  Urban
//
//  Created by Kangtle on 8/27/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit

class VideoTableViewCell: UITableViewCell {

    
    
    @IBOutlet weak var videoThumbView: UIImageView!
    @IBOutlet weak var videoNameLabel: UILabel!
    @IBOutlet weak var videoDurationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        videoThumbView.layer.cornerRadius = videoThumbView.frame.width/2
        videoThumbView.clipsToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }


}
