//
//  ReferralProgramVC.swift
//  Urban
//
//  Created by Kangtle on 8/24/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase

let DYNAMIC_ROOT_LINK = "https://s53je.app.goo.gl/"
let APP_STORE_ID = "585027354" //google map test
let TEST_DIAWI_URL = "https://i.diawi.com/UTXzCw"
let BUNDLE_ID = "com.travis.Urban"

//Refer https://firebase.google.com/docs/dynamic-links/create-manually

class ReferralProgramVC: UIViewController {
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var referralLinkEdit: UITextField!
    @IBOutlet weak var balanceLabel: UILabel!

    var user: User!

    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toolBar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        
        self.balanceLabel.text = "AUD  \(APPDELEGATE.currenntUser.balance ?? 0.00)"
        
        let link = "https://urban.travis.com/?invite=\(user.id ?? "")"

        //        let referralLink = "\(DYNAMIC_ROOT_LINK)?link=\(link)&ibi=\(BUNDLE_ID)&isi=\(APP_STORE_ID)" //Live
        let referralLink = "\(DYNAMIC_ROOT_LINK)?link=\(link)&ibi=\(BUNDLE_ID)&ifl=\(TEST_DIAWI_URL)" //Test
        referralLinkEdit.text = referralLink
    }

    @IBAction func onBack(_ sender: Any) {
        self.performSegueToReturnBack()
    }

    @IBAction func onPressedShare(_ sender: Any) {
        let referralLink = referralLinkEdit.text
        let vc = UIActivityViewController(activityItems: [referralLink ?? ""], applicationActivities: nil)
        self.present(vc, animated: true, completion: nil)
    }

}
