//
//  TrainerTableCell.swift
//  Urban
//
//  Created by Kangtle on 8/12/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit

class TrainerTableCell: UITableViewCell {

    @IBOutlet weak var trainerImageView: UIImageView!
    @IBOutlet weak var trainerNameLabel: UILabel!
    @IBOutlet weak var trainerQualificationLabel: UILabel!
    @IBOutlet weak var trainerRatingView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        trainerImageView.layer.cornerRadius = trainerImageView.frame.width/2
        trainerImageView.clipsToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    var trainerRating: Int? = nil {
        didSet {
            let ratingStars = trainerRatingView.subviews
            let emptyStarsCount = 5 - trainerRating!
            for index in 0...4 {
                let ratingStar = ratingStars[index]
                if index < emptyStarsCount {
                    ratingStar.isHidden = true
                }else{
                    ratingStar.isHidden = false
                }
            }
        }
    }

}
