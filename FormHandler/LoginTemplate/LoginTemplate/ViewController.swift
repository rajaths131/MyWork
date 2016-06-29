//
//  ViewController.swift
//  LoginTemplate
//
//  Created by Rajath K Shetty on 25/05/16.
//  Copyright Rajath. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet var rootContainerScrollView: UIScrollView!
    @IBOutlet var orderedTextFields: [UIView]!
    var textViewDelegate: UITextViewDelegate? {
        return nil
    }
    
    var textFieldDelegate: UITextFieldDelegate? {
        return nil
    }

    var keyboardHander: KeyboardHandler!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        keyboardHander = KeyboardHandler(helper: self, shouldObserverKeyboardNotification: true)
    }
}

extension ViewController: KeyboardHandlerHelper {
    
    func doneButtonType() -> UIReturnKeyType {
        return .Done
    }
    
    func validateItemAtIndex(index: Int, text: String) -> Bool {
        
        switch index {
        case 0:
            return text.isValidEmail()
        case 1:
            return text.length() > 0
        default:
            return true
        }
    }
    
    func cleanupErrorMessageIfExist() -> Void {
        errorMessage.text = ""
    }
    
    func submitButtonTapped() -> Void {
        //Make your network operation
    }
    
    @IBAction func login(sender: UIButton) {
        if let indexes = keyboardHander.validateInputFields() {
            errorMessage.text = "Please enter proper message"
            print(indexes)
            //Show error for all the failed indexes.
        } else {
            //Make your network operation
        }
    }
}

