//
//  TermsVC.swift
//  Urban
//
//  Created by Kangtle on 8/24/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit

class TermsVC: UIViewController {
    @IBOutlet weak var toolBar: UIToolbar!

    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        toolBar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onBack(_ sender: Any) {
        self.performSegueToReturnBack()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
