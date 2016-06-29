//
//  ViewController.swift
//  SocialLogin
//
//  Created by Rajath K Shetty on 22/06/16.
//  Copyright Rajath. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBAction func gmailLogin(sender: UIButton) {
        ABSocialManager.sharedInstance.loginToGooglePlusWithScopes(["https://www.googleapis.com/auth/contacts.readonly"]) { (success, error, info) in
            
        }
    }

    @IBAction func facebookLogin(sender: UIButton) {
        ABSocialManager.sharedInstance.loginToFacebookWithReadPermission(["email"]) { (success, error, info) in
            
        }
    }
    
    @IBAction func twitterLogin(sender: UIButton) {
        ABSocialManager.sharedInstance.loginToTwitter { (success, error, info) in
            
        }
    }
    
}

