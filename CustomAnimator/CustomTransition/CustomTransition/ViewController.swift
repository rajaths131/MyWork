//
//  ViewController.swift
//  CustomTransition
//
//  Created by Rajath K Shetty on 23/06/16.
//  Copyright Rajath. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var pushSwitch: UISwitch!
    var animator: RevealAnimator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func present(sender: UIButton) {
        
        let controller = self.storyboard?.instantiateViewControllerWithIdentifier("SecondViewController")
        controller!.view.backgroundColor = UIColor.redColor()
        self.animator = RevealAnimator.animator()
        animator!.shouldPush = pushSwitch.on
        animator!.revealType = RevealAnimator.RevealType(rawValue: segmentControl.selectedSegmentIndex)!
        animator!.presentController(controller!, fromController: self)

    }

}

