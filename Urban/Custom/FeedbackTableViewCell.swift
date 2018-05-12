//
//  FeedbackTableViewCell.swift
//  Urban
//
//  Created by Kangtle on 9/7/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit

class FeedbackTableViewCell: UITableViewCell {

    @IBOutlet weak var clientImageview: UIImageView!
    @IBOutlet weak var feedbackLabel: UILabel!
    @IBOutlet weak var nameAndTimeLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        clientImageview.layer.cornerRadius = clientImageview.frame.width/2
        clientImageview.clipsToBounds = true

        self.feedbackLabel.numberOfLines = 0
        self.feedbackLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
//        self.feedbackLabel.sizeToFit()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func height() -> Int {
        let height = 10 + // top padding
                     feedbackLabel.frame.height +
                     10 + // middle padding
                     nameAndTimeLabel.frame.height +
                     10 // bottom padding
        return Int(height)
    }

}
