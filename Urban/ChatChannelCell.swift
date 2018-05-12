//
//  ChatChannelCell.swift
//  Urban
//
//  Created by Kangtle on 8/18/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit

class ChatChannelCell: UITableViewCell {

    @IBOutlet weak var opponentImageView: UIImageView!
    @IBOutlet weak var opponentNameLabel: UILabel!
    @IBOutlet weak var lastMessageTimeLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var justNowImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        opponentImageView.layer.cornerRadius = opponentImageView.frame.width/2
        opponentImageView.clipsToBounds = true

        myImageView.layer.cornerRadius = myImageView.frame.width/2
        myImageView.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
