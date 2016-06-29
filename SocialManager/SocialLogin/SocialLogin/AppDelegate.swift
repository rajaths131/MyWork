//
//  AppDelegate.swift
//  SocialLogin
//
//  Created by Rajath K Shetty on 22/06/16.
//  Copyright Rajath. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        ABSocialManager.sharedInstance.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Override point for customization after application launch.
        return true
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        
        ABSocialManager.sharedInstance.activateApp()
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return ABSocialManager.sharedInstance.application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
}

