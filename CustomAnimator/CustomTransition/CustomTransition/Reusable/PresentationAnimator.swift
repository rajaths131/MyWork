//
//  JPOverlayAnimator.swift
//  JiyoPublisher
//
//  Created by Rajath Shetty on 24/03/16.
//  Copyright Rajath Solution. All rights reserved.
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
            setupViewsForAnimation(fromController, toController: toController, fromView: fromView, toView: toView, containerView: containerView)
            
            willStartPresentationAnimationWithFromView(fromController, toController: toController, fromView: fromView, toView: toView, containerView: containerView)
            containerView.addSubview(toView)
            UIView.animateWithDuration(duration, animations: { [weak self] () -> Void in
                self?.animatingPresentationAnimationWithFromView(fromController, toController: toController, fromView: fromView, toView: toView, containerView: containerView)
                }, completion: { [weak self] (success) -> Void in
                    self?.didCompletePresentationAnimationWithFromView(fromController, toController: toController, fromView: fromView, toView: toView, containerView: containerView)
                    transitionContext.completeTransition(success)
            })
            
        } else {
            willStartDismissAnimationWithFromView(fromController, toController: toController, fromView: fromView, toView: toView, containerView: containerView)
            UIView.animateWithDuration(duration, animations: { [weak self] () -> Void in
                self?.animatingDismissWithFromView(fromController, toController: toController, fromView: fromView, toView: toView, containerView: containerView)
                }, completion: { [weak self] (success) -> Void in
                    self?.didCompleteDismissWithFromView(fromController, toController: toController, fromView: fromView, toView: toView, containerView: containerView)
                    fromView.removeFromSuperview()
                    transitionContext.completeTransition(success)

                })
        }
    }
    
    func setupViewsForAnimation(fromController:UIViewController, toController: UIViewController, fromView: UIView, toView: UIView, containerView: UIView) {
        
    }
    
    func willStartPresentationAnimationWithFromView(fromController:UIViewController, toController: UIViewController, fromView: UIView, toView: UIView, containerView: UIView) {
        toView.transform = CGAffineTransformMakeScale(0, 0)
        toView.alpha = 0.0
    }

    func animatingPresentationAnimationWithFromView(fromController:UIViewController, toController: UIViewController, fromView: UIView, toView: UIView, containerView: UIView) {
        toView.transform = CGAffineTransformIdentity
        toView.alpha = 1.0
    }
    
    func didCompletePresentationAnimationWithFromView(fromController:UIViewController, toController: UIViewController, fromView: UIView, toView: UIView, containerView: UIView) {
        
    }
    
    func willStartDismissAnimationWithFromView(fromController:UIViewController, toController: UIViewController, fromView: UIView, toView: UIView, containerView: UIView) {
        
    }
    
    func animatingDismissWithFromView(fromController:UIViewController, toController: UIViewController, fromView: UIView, toView: UIView, containerView: UIView) {
        willStartPresentationAnimationWithFromView(toController, toController: fromController, fromView: toView, toView: fromView, containerView: containerView)
    }

    func didCompleteDismissWithFromView(fromController:UIViewController, toController: UIViewController, fromView: UIView, toView: UIView, containerView: UIView) {
        
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

