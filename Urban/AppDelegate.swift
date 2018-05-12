//
//  AppDelegate.swift
//  Urban
//
//  Created by Kangtle on 8/4/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import Firebase
import GoogleMaps
import GooglePlaces
import Braintree

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var currenntUser: User!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        print(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? "");
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        IQKeyboardManager.sharedManager().enable = true
        
        FirebaseOptions.defaultOptions()?.deepLinkURLScheme = "com.travis.Urban"
        FirebaseApp.configure()
        
        GMSServices.provideAPIKey("AIzaSyA3pSBg7MiAL7STibt64U2vS9WmLpV-1y8")
        GMSPlacesClient.provideAPIKey("AIzaSyA3pSBg7MiAL7STibt64U2vS9WmLpV-1y8")
 
        BTAppSwitch.setReturnURLScheme("com.travis.Urban.payments")
        
        let defaults = UserDefaults.standard
        
        if !defaults.bool(forKey: "has_run_before") {
            do {
                try Auth.auth().signOut()
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
            defaults.set(true, forKey: "has_run_before")
            defaults.synchronize()
        }
        
        if(Auth.auth().currentUser==nil){
            let signinNC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SigninNC") as! UINavigationController
            self.window?.rootViewController = signinNC
        }else{
            print("current user id", Auth.auth().currentUser?.uid ?? "")
            let defaults = UserDefaults.standard
            let isTrainer = defaults.bool(forKey: "is_trainer")
            if isTrainer {
                let mainTab = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TrainerTab") as! UITabBarController
                self.window?.rootViewController = mainTab
            }else{
                if Auth.auth().currentUser?.email == ADMIN_EMAIL {
                    let nav = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AdminNav") as! UINavigationController
                    self.window?.rootViewController = nav
                }else{
                    let mainTab = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainTab") as! UITabBarController
                    self.window?.rootViewController = mainTab
                }
            }
        }
        locManager.requestWhenInUseAuthorization()
        
        self.window?.makeKeyAndVisible()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        UIApplication.shared.isIdleTimerDisabled = true

    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return application(app, open: url, sourceApplication: nil, annotation: [:])
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if url.scheme?.localizedCaseInsensitiveCompare("com.travis.Urban.payments") == .orderedSame {
            return BTAppSwitch.handleOpen(url, sourceApplication: sourceApplication)
        }
        
        let dynamicLink = DynamicLinks.dynamicLinks()?.dynamicLink(fromCustomSchemeURL: url)
//        Helper.showMessage(target: (window?.rootViewController)!, title: "", message: url.absoluteString)
        if let dynamicLink = dynamicLink {
            // Handle the deep link. For example, show the deep-linked content or
            // apply a promotional offer to the user's account.
            // ...
            print("deep_link", dynamicLink.url?.queryParameters ?? [:])
            
            if let inviteFrom = dynamicLink.url?.queryParameters?["invite"] {
                UserDefaults.standard.set(inviteFrom, forKey: "invite_from")
            }
            
            return true
        }
        
        return false
    }

}

