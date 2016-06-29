//
//  JPOverlayAnimator.swift
//  JiyoPublisher
//
//  Created by Rajath Shetty on 24/03/16.
//  Copyright © 2016 Above Solution. All rights reserved.
//

import UIKit

//MARK: UIViewController extension

/**
 Extend UIViewController to dismiss view controller easily.
 */
extension UIViewController {
    @IBAction func dismissController() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

//MARK: PresentationAnimator public methods

/**
 This can used as custom transition animator base class, subclssing will reduce the work u need to do.
 
 */
class PresentationAnimator: NSObject {
    
    //Need to update this value, for right animation to execute.
    var isPresenting: Bool = true
    
    required override init() {
        super.init()
    }
    
    /**
     Return a animator object, even subclass can use this method to create its instance.
     */
    class func animator() -> Self {
        let animator = self.init()
        return animator
    }

    /**
     This will take all the responsibility of presenting new view controller, with custom animation.
     
     - Parameter controller: View controller to b presented
     - Parameter FromController: View controller from which you are presenting this view controller.
     
     - Note : Keep a strong reference to this animator, else dismiss animation won't happen as expected.
     */
    func presentController(controller: UIViewController, fromController: UIViewController) {
        controller.modalPresentationStyle = .Custom
        controller.transitioningDelegate = self
        fromController.presentViewController(controller, animated: true, completion: nil)
    }
}

//MARK: PresentationAnimator, UIViewControllerTransitioningDelegate methods

extension PresentationAnimator: UIViewControllerTransitioningDelegate {
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self;
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.isPresenting = false
        return self
    }
}

//MARK: PresentationAnimator, UIViewControllerAnimatedTransitioning methods

extension PresentationAnimator: UIViewControllerAnimatedTransitioning{
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.5
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toView = toViewController.view
        let fromView = fromViewController.view
        let containerView = transitionContext.containerView()!
        let duration = self .transitionDuration(transitionContext)
        
        animateFromController(fromViewController, toController: toViewController, fromView: fromView, toView: toView, containerView: containerView, duration: duration, transitionContext: transitionContext)
    }
}

//MARK: Custom methods

extension PresentationAnimator {
    
    /**
     This mathod will be called with all the required parameter to implement the animation.
     
     - Parameter fromController: Controller from new view controller is presented or controller which is dismissed.
     - Parameter toController: Presenting controller or controler which presented, current dismissing controller.
     - Parameter fromView: view of fromController
     - Parameter toView: view of toController 
     - Parameter duration: duration for animation
     - Parameter transitionContext: Contect of animation.
     
     Note: Depending on the isPresenting falg status, you need to implement presentation or dismiss animation.
     */
    func animateFromController(fromController:UIViewController, toController: UIViewController, fromView: UIView, toView: UIView, containerView: UIView, duration: NSTimeInterval, transitionContext: UIViewControllerContextTransitioning) {
        
        if isPresenting {
            setupForAnimationFromController(fromController, toController: toController, fromView: fromView, toView: toView, containerView: containerView)
            
            setupBeforAnimationFromView(fromView, toView: toView)
            containerView.addSubview(toView)
            UIView.animateWithDuration(duration, animations: { [weak self] () -> Void in
                self?.setupForPresentationAnimationFromView(fromView, toView: toView)
                }, completion: { (success) -> Void in
                    transitionContext.completeTransition(success)
            })
            
        } else {
            UIView.animateWithDuration(duration, animations: { [weak self] () -> Void in
                self?.setupDismissAnimationFromView(fromView, toView: toView)
                }, completion: { [weak self] (success) -> Void in
                    fromView.removeFromSuperview()
                    transitionContext.completeTransition(success)
                    self?.cleanUpFromController(fromController, toController: toController, fromView: fromView, toView: toView, containerView: containerView)
                })
        }
    }
    
    /**
     Ui setup for presentation animation.
     */
    func setupForAnimationFromController(fromController:UIViewController, toController: UIViewController, fromView: UIView, toView: UIView, containerView: UIView) {
        
    }
    
    /**
     Initial setup before presntation animation.
     */
    func setupBeforAnimationFromView(fromView: UIView, toView: UIView) {
        toView.transform = CGAffineTransformMakeScale(0, 0)
        toView.alpha = 0.0
    }
    
    /**
     Setup views for presentation animation
     */
    func setupForPresentationAnimationFromView(fromView: UIView, toView: UIView) {
        toView.transform = CGAffineTransformIdentity
        toView.alpha = 1.0
    }
    
    /**
     Setup view for dismiss animation.
     */
    func setupDismissAnimationFromView(fromView: UIView, toView: UIView) {
        setupBeforAnimationFromView(toView, toView: fromView)
    }
    
    /**
     Clean up after dismiss animation completes.
     */
    func cleanUpFromController(fromController:UIViewController, toController: UIViewController, fromView: UIView, toView: UIView, containerView: UIView) {
        
    }
}

class RevealAnimator: PresentationAnimator {
    
    /**
     RevealType represents different sides of screen from which new view controller can reveal.
     */
    enum RevealType : Int {
        case Left, Right, Bottom, Top
        
        func percentageValueX(value: CGFloat, frame: CGRect) -> CGFloat {
            switch self {
            case .Left:
                return -frame.width
            case .Right:
                return frame.width
            default:
                return 0.0
            }
        }
        
        func percentageValueY(value: CGFloat, frame: CGRect) -> CGFloat {
            switch self {
            case .Top:
                return -frame.height
            case .Bottom:
                return frame.height
            default:
                return 0.0
            }
        }
        
        func presentedViewForFrame(frame: CGRect, percentage: CGFloat) -> CGRect {
            switch self {
            case .Top:
                return CGRectMake(frame.origin.x, frame.origin.y, frame.width, frame.height * percentage)
            case .Bottom:
                let height = frame.height * percentage
                return CGRectMake(frame.origin.x, frame.height - height, frame.width, height)
            case .Left:
                return CGRectMake(frame.origin.x, frame.origin.y, frame.width * percentage, frame.height)
            case .Right:
                let width = frame.width * percentage
                return CGRectMake(frame.width - width, frame.origin.y, frame.width * percentage, frame.height)
            }
        }
    }
    
    var shouldPush: Bool = true
    var revealType: RevealType = .Left
    var percetageToCover: CGFloat = 0.8
    
    private weak var blurView: UIView?
    private weak var presentedController: UIViewController?
    
    override func setupForAnimationFromController(fromController:UIViewController, toController: UIViewController, fromView: UIView, toView: UIView, containerView: UIView) {
        toView.frame = revealType.presentedViewForFrame(fromView.bounds, percentage: percetageToCover)
        
        //add gesture recognizer and blur view
        if self.blurView == nil {
            let blurView = UIView(frame: fromView.bounds)
            blurView.backgroundColor = UIColor(red: 0.0, green: 0, blue: 0, alpha: 0.0)
            containerView.addSubview(blurView)
            
            self.blurView = blurView
            self.presentedController = toController
            
            let gesture = UITapGestureRecognizer(target: fromController, action:#selector(UIViewController.dismissController))
            gesture.numberOfTapsRequired = 1
            blurView.addGestureRecognizer(gesture)
        }
    }
    
    override func setupBeforAnimationFromView(fromView: UIView, toView: UIView) {
        toView.transform = CGAffineTransformMakeTranslation(revealType.percentageValueX(1, frame: toView.frame), revealType.percentageValueY(1, frame: toView.frame))
        blurView?.backgroundColor = UIColor(red: 0.0, green: 0, blue: 0, alpha: 0.0)

        if shouldPush {
            fromView.transform = CGAffineTransformIdentity
        }
    }
    
    override func setupForPresentationAnimationFromView(fromView: UIView, toView: UIView) {
        toView.transform = CGAffineTransformIdentity
        blurView?.backgroundColor = UIColor(red: 0.0, green: 0, blue: 0, alpha: 0.5)

        if shouldPush {
            fromView.transform = CGAffineTransformMakeTranslation(-revealType.percentageValueX(percetageToCover, frame: toView.frame), -revealType.percentageValueY(percetageToCover, frame: toView.frame))
        }
    }
    
    override func cleanUpFromController(fromController:UIViewController, toController: UIViewController, fromView: UIView, toView: UIView, containerView: UIView) {
        blurView?.removeFromSuperview()
    }
}

class JPOverlayAnimator: PresentationAnimator{
    
    override func animateFromController(fromController:UIViewController, toController: UIViewController, fromView: UIView, toView: UIView, containerView: UIView, duration: NSTimeInterval, transitionContext: UIViewControllerContextTransitioning) {
        
        if isPresenting {
            toView.transform = CGAffineTransformMakeScale(0, 0)
            toView.alpha = 0.0
            containerView.addSubview(toView)
            UIView.animateWithDuration(duration, animations: { () -> Void in
                toView.transform = CGAffineTransformIdentity
                toView.alpha = 1.0
                }, completion: { (success) -> Void in
                    transitionContext.completeTransition(success)
            })
            
        } else {
            UIView.animateWithDuration(duration, animations: { () -> Void in
                fromView.transform = CGAffineTransformMakeScale(0, 0)
                toView.alpha = 0.0
                }, completion: { (success) -> Void in
                    fromView.removeFromSuperview()
                    transitionContext.completeTransition(success)
            })
        }
        
    }
}

