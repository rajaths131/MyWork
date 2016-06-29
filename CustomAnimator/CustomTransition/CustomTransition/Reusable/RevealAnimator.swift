//
//  RevealAnimator.swift
//  CustomTransition
//
//  Created by Rajath K Shetty on 23/06/16.
//  Copyright Rajath. All rights reserved.
//

import UIKit

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
    
    override func setupViewsForAnimation(fromController:UIViewController, toController: UIViewController, fromView: UIView, toView: UIView, containerView: UIView) {
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
    
    override func willStartPresentationAnimationWithFromView(fromController:UIViewController, toController: UIViewController, fromView: UIView, toView: UIView, containerView: UIView) {
        toView.transform = CGAffineTransformMakeTranslation(revealType.percentageValueX(1, frame: toView.frame), revealType.percentageValueY(1, frame: toView.frame))
        blurView?.backgroundColor = UIColor(red: 0.0, green: 0, blue: 0, alpha: 0.0)
        
        if shouldPush {
            fromView.transform = CGAffineTransformIdentity
        }
    }
    
    override func animatingPresentationAnimationWithFromView(fromController:UIViewController, toController: UIViewController, fromView: UIView, toView: UIView, containerView: UIView) {
        toView.transform = CGAffineTransformIdentity
        blurView?.backgroundColor = UIColor(red: 0.0, green: 0, blue: 0, alpha: 0.5)
        
        if shouldPush {
            fromView.transform = CGAffineTransformMakeTranslation(-revealType.percentageValueX(percetageToCover, frame: toView.frame), -revealType.percentageValueY(percetageToCover, frame: toView.frame))
        }
    }
    
    override func didCompleteDismissWithFromView(fromController:UIViewController, toController: UIViewController, fromView: UIView, toView: UIView, containerView: UIView) {
        blurView?.removeFromSuperview()
    }
}
