//
//  WelcomePageVC.swift
//  Urban
//
//  Created by Kangtle on 8/7/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit

class WelcomePageVC: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var scrollView: UIScrollView!
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.contentSize.width = scrollView.frame.width * CGFloat(pageControl.numberOfPages)
        // Do any additional setup after loading the view.
    }
    func scrollViewDidScroll(_ _scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.size.width
        let currentPosition = scrollView.contentOffset.x
        let currentPage = currentPosition/pageWidth
        pageControl.currentPage = Int(currentPage)
    }
    
    @IBAction func onValueChangedPageControl(_ sender: Any) {
        let currentPage = pageControl.currentPage
        let pageWidth = scrollView.frame.size.width
        scrollView.contentOffset.x = pageWidth * CGFloat(currentPage)
    }
    @IBAction func onPressedExplore(_ sender: Any) {
        let defaults = UserDefaults.standard
        let isTrainer = defaults.bool(forKey: "is_trainer")
        if isTrainer {
            self.performSegue(withIdentifier: "TrainerTab", sender: self)
        }else{
            self.performSegue(withIdentifier: "WelcomeToMain", sender: self)
        }
    }
}
