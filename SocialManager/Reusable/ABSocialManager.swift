//
//  ABSocialManager.swift
//  ReusableSample
//
//  Created by Rajath Shetty on 08/03/16.
//  Copyright Rajath Solution. All rights reserved.
//
import UIKit

extension UIApplication {
    
    class func currentSize() -> CGSize {
        return UIApplication.sizeInOrientation(UIApplication.sharedApplication().statusBarOrientation)
    }
    
    class func sizeInOrientation(orientation: UIInterfaceOrientation) -> CGSize {
        var size = UIScreen.mainScreen().bounds.size
        let application = UIApplication.sharedApplication()
        if (UIInterfaceOrientationIsLandscape(orientation)) {
            size = CGSizeMake(size.height, size.width)
        }
        
        if (!application.statusBarHidden) {
            size.height -= min(application.statusBarFrame.size.width, application.statusBarFrame.size.height)
        }
        return size;
    }
    
    class func getRootViewController() -> UIViewController? {
        var presentedVC = UIApplication.sharedApplication().keyWindow?.rootViewController
        while let pVC = presentedVC?.presentedViewController
        {
            presentedVC = pVC
        }
        
        return presentedVC
    }
}

#if FACEBOOK
    import FBSDKCoreKit
    import FBSDKLoginKit
#endif

#if TWITTER
    import TwitterKit
#endif

enum ABSocialNetworkType : Int {
    case Facebook = 0, Twitter, GooglePlus
}

/**
 This will make Twitter, Facebook and GooglePlus login simple.
 You can optionally include the sdk, depending on the services you want, we suggest you to use cocoapod for including SDK. It incudes all dependent SDKs to your project. make your life much simpler.
 
 To get Facebook Service:
 1. Configure you application to use facebook sdk(Create application, Include SDK, Add FacebookAppId and Configure URL schemes), Check https://developers.facebook.com/docs/ios/getting-started
 2. Import this framework in swift bridge header.
 #import <FBSDKLoginKit/FBSDKLoginKit.h>
 #import <FBSDKCoreKit/FBSDKCoreKit.h>
 3. Add "Other Swift flag" in build settings as "-D FACEBOOK"
 4. Use ABSocialManager
 
 To get Google Plus Service:
 1. Configure you application to use google sdk(Create application, Include SDK, Add google Service-Info.plist and Configure URL schemes), Check https://developers.google.com/identity/sign-in/ios/start
 2. Import this framework in swift bridge header.
 #import <GoogleSignIn/GoogleSignIn.h>
 #import <Google/Core.h>
 3. Add "Other Swift flag" in build settings as "-D GOOGLEPLUS"
 4. Use ABSocialManager
 
 To get Twitter Service:
 1. Install Fabric application and setup your application to use SDK.(Fabric application gives setp by step instruction for setup Project like, Inculde SDK, add key-values to Info.plist, add run script)
 2. Create application in twitter and add consumerKey and consumerSecret to plist
 3. Import this framework in swift bridge header.
 #import <Fabric/Fabric.h>
 4. Add "Other Swift flag" in build settings as "-D TWITTER" to get twitter service
 5. Add "Other Swift flag" in build settings as "-D CRASHLYTICS" to get crashlytics
 
 You need to call some setup method in ypur application delegate methods.
 */
class ABSocialManager: NSObject {
    
    let SocialLoginInfo: String = "SocialLoginInfo"
    
    /**
     This is the completion handler for all type oflogin request.
     
     - Parameter success: Return the status of login.
     - Parameter error  : Error, if login request failed.
     - Parameter info   : User login information. This is a dictionary and you can access the information with key "SocialLoginInfo".
     
     - Note: User info object varies dipending on the type of request you make, For facebook - FBSDKLoginManagerLoginResult, twitter - TWTRSession, GooglePlus-GIDGoogleUser
     */
    typealias SocialLoginResponseHandler = (success: Bool, error: NSError?, info: [String : AnyObject]?) -> Void
    
    static let sharedInstance = ABSocialManager()
    var signInHandler: SocialLoginResponseHandler?
    
    //MARK: Setup methods
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) {
        
        #if FACEBOOK
            FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        #endif
        
        #if TWITTER || CRASHLYTICS
            //for crashlytics
            var objects: [AnyObject] = []
            #if TWITTER
                objects.append(Twitter.sharedInstance())
            #endif
            #if CRASHLYTICS
                objects.append(Crashlytics.sharedInstance())
            #endif
            if objects.count > 0 {
                Fabric.with(objects)
                FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
            }
            
        #endif
        
        #if GOOGLEPLUS
            var configureError: NSError?
            GGLContext.sharedInstance().configureWithError(&configureError)
            assert(configureError == nil, "Error configuring Google services: \(configureError)")
            GIDSignIn.sharedInstance().delegate = self
            GIDSignIn.sharedInstance().uiDelegate = self
        #endif
        
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        let result = false
        
        #if FACEBOOK
            if (FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)) {
                return true
            }
        #endif
        
        #if GOOGLEPLUS
            if (GIDSignIn.sharedInstance().handleURL(url, sourceApplication: sourceApplication, annotation: annotation))
            {
                return true
            }
        #endif
        
        return result
    }
    
    func activateApp() {
        #if FACEBOOK
            FBSDKAppEvents.activateApp()
        #endif
    }
    
    func logout() {
        #if FACEBOOK
            FBSDKLoginManager().logOut()
        #endif
        
        #if GOOGLEPLUS
            GIDSignIn.sharedInstance().signOut()
        #endif
        
        #if TWITTER
            let store = Twitter.sharedInstance().sessionStore
            if let userID = store.session()?.userID {
                store.logOutUserID(userID)
            }
        #endif
    }
}

private extension ABSocialManager {
    func getRootViewController() -> UIViewController? {
        var presentedVC = UIApplication.sharedApplication().keyWindow?.rootViewController
        while let pVC = presentedVC?.presentedViewController
        {
            presentedVC = pVC
        }
        
        return presentedVC
    }
    
    func executeHandler(handler: SocialLoginResponseHandler?, status: Bool, error: NSError?, info: AnyObject?) {
        if handler != nil {
            let dist: [String : AnyObject]? = ((info != nil) ? [self.SocialLoginInfo : info!] : nil)
            handler!(success: status, error: error, info: dist)
        }
    }
}

#if TWITTER
    extension ABSocialManager {
        
        /**
         Login to twitter.
         
         - Parameter completionHandler: Callback on completion of login
         */
        func loginToTwitter(completionHandler: SocialLoginResponseHandler? ) {
            
            Twitter.sharedInstance().logInWithCompletion { [weak self] (session, error) -> Void in
                
                self?.executeHandler(completionHandler, status: session != nil, error: error, info: session)
            }
        }
    }
#endif

#if FACEBOOK
    extension ABSocialManager {
        
        /**
         Login to facebook with read permessions.
         
         - Parameter permission: Read permissions array for facebook login like, email
         - Parameter completionHandler: Callback on completion of login
         */
        func loginToFacebookWithReadPermission(permissions: [String], completionHandler: SocialLoginResponseHandler? ) {
            loginToFacebookWithPermission(permissions, isPublish: false, handler: completionHandler)
        }
        
        /**
         Login to facebook with Publish permessions.
         
         - Parameter permission: Publish permissions array for facebook login like, publish_actions
         - Parameter completionHandler: Callback on completion of login
         */
        func loginToFacebookWithPublishPermission(permissions: [String], completionHandler: SocialLoginResponseHandler? ) {
            loginToFacebookWithPermission(permissions, isPublish: true, handler: completionHandler)
        }
        
        private func loginToFacebookWithPermission(permission: [String], isPublish: Bool, handler: SocialLoginResponseHandler?) {
            
            let facebookHandler = { [weak self] (loginResult: FBSDKLoginManagerLoginResult!, error: NSError!) -> Void  in
                if error != nil {
                    self?.executeHandler(handler, status: false, error: error, info: loginResult)
                } else if loginResult.isCancelled {
                    self?.executeHandler(handler, status: false, error: error, info: loginResult)
                } else {
                    self?.executeHandler(handler, status: true, error: error, info: loginResult)
                }
            }
            let fbLogin = FBSDKLoginManager()
            if isPublish == false {
                fbLogin.logInWithReadPermissions(permission, fromViewController: UIApplication.getRootViewController(), handler: facebookHandler)
            } else {
                fbLogin.logInWithPublishPermissions(permission, fromViewController: UIApplication.getRootViewController(), handler: facebookHandler)
            }
        }
    }
    
#endif

#if GOOGLEPLUS
    extension ABSocialManager {
        
        /**
         Login to Google Plus
         
         - Parameter scopes: Scopes for GooglePlus login
         - Parameter completionHandler: Callback on completion of login
         */
        func loginToGooglePlusWithScopes(scopes: [String], completionHandler: SocialLoginResponseHandler? ) {
            signInHandler = completionHandler
            let signIn = GIDSignIn.sharedInstance()
            signIn.scopes = scopes
            signIn.delegate = self
            signIn.signIn()
        }
    }
    
    extension ABSocialManager: GIDSignInDelegate {
        
        func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!) {
            if signInHandler != nil {
                executeHandler(signInHandler, status: (error == nil), error: error, info: user)
            }
            signInHandler = nil
        }
    }
    
    extension ABSocialManager: GIDSignInUIDelegate {
        func signIn(signIn: GIDSignIn!, presentViewController viewController: UIViewController!) {
            getRootViewController()?.presentViewController(viewController, animated: true, completion: nil)
        }
    }
#endif