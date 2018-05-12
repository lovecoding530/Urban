//
//  WorkoutCollectionCell.swift
//  Urban
//
//  Created by Kangtle on 8/13/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit

class WorkoutCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var workoutImageView: UIImageView!
    @IBOutlet weak var workoutNameLabel: UILabel!
    var gradientLayer: CAGradientLayer! = nil
    
    override func layoutSubviews() {
        gradientLayer.frame = self.bounds
        workoutImageView.frame = self.bounds
        workoutNameLabel.frame.origin.y = self.frame.height - 20
    }
}
