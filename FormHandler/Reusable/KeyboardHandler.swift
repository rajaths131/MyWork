//
//  KeyboardHandler.swift
//  LoginTemplate
//
//  Created by Rajath K Shetty on 25/05/16.
//  Copyright Rajath. All rights reserved.
//

import UIKit

protocol KeyboardHandlerHelper {
    //Root container scroll view, all content of this page should be there inside this scrollview/
    var rootContainerScrollView: UIScrollView! { get }
    
    //If you need any call back from text view or text field, which you set in orderedTextFields
    //set this delegate
    var textViewDelegate: UITextViewDelegate? { get }
    var textFieldDelegate: UITextFieldDelegate? { get }
    
    //List of all the text fields and text view in order
    var orderedTextFields: [UIView]! { get }
    
    //Keyboard return button type, when all valid inputs are entered.
    func doneButtonType() -> UIReturnKeyType
    
    //Is text is valid for input field at index
    func validateItemAtIndex(index: Int, text: String) -> Bool
    
    //This method give option for clean up error message.
    func cleanupErrorMessageIfExist() -> Void
    
    //This method is called, when done button is tapped in keyboard
    func submitButtonTapped() -> Void
}

extension String {
    func isValidEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return isValidForRegex(emailRegex)
    }
    
    func isValidMobileNumber() -> Bool {
        let phoneRegex = "([+]?([0-9]{1,2})[-]?)?[0-9]{10}"
        return isValidForRegex(phoneRegex)
    }
    
    func isValidUrlWithoutHttp() -> Bool {
        let phoneRegex = "[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}$"
        return isValidForRegex(phoneRegex)
    }
    
    
    func isValidForRegex(regex: String) -> Bool {
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluateWithObject(self)
    }
    
    func length() -> Int {
        return self.characters.count
    }
}

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
}

extension NSNotificationCenter {
    
    class func registerForKeyboardNotificationObject(object: AnyObject, appearenceSelector: Selector, disappearenceSelector: Selector) {
        NSNotificationCenter.defaultCenter().addObserver(object, selector: appearenceSelector, name: UIKeyboardDidShowNotification , object: nil)
        NSNotificationCenter.defaultCenter().addObserver(object, selector: disappearenceSelector, name: UIKeyboardDidHideNotification , object: nil)
    }
    
    class func registerForKeyboardNotificationObject(object: AnyObject) {
        NSNotificationCenter.defaultCenter().removeObserver(object, name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(object, name: UIKeyboardDidHideNotification, object: nil)
    }
}

/**
 KeyboardHandler will help to,
 
    1. layout view when keyboard appears or disappears.
    2. Set keyboard return button
    3. Help validation of input fields easily.
 Must do:
    1. If shouldObserverKeyboardNotification is passed in initializer,KeyboardHandler will handle everything for you. If you want keyboard event in your object, in notification handler method you can call handleKeyboardAppearence() and handleKeyboardDisappearance().
    2. If you need text field or text view delegate call back, implement KeyboardHandlerHelper and return delegate
 */
class KeyboardHandler: NSObject {
    
    var helper: KeyboardHandlerHelper
    var shouldObserverKeyboardNotification: Bool = true
    
    
    //Set this property to first responder, to scroll to right position.
    weak var currentFirstResponder: UIView?
    weak var tapGesture: UITapGestureRecognizer?
    
    init(helper: KeyboardHandlerHelper, shouldObserverKeyboardNotification: Bool) {
        
        //set properties
        self.helper = helper
        self.shouldObserverKeyboardNotification = shouldObserverKeyboardNotification
        super.init()
        
        if shouldObserverKeyboardNotification {
            addKeyboardNotificationObserver()
        }
        
        for view in helper.orderedTextFields {
            if let textfield = view as? UITextField {
                textfield.delegate = self
            } else if let textView = view as? UITextView {
                textView.delegate = self
            }
        }
        
        //Add tap gestures
        if tapGesture == nil {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(KeyboardHandler.handleTapGesture(_:)))
            helper.rootContainerScrollView.addGestureRecognizer(tapGesture)
            self.tapGesture = tapGesture
            tapGesture.numberOfTapsRequired = 1
        }
    }
    
    deinit {
        removeKeyboardNotificationObserver()
    }
    
    /**
     This will initialize validation of text fields and returns index of input fields, which fails
     It will call validateItemAtIndex() on every input field for validation.
     */
    func validateInputFields() -> [Int]? {
        
        helper.cleanupErrorMessageIfExist()
        
        var indexes: [Int] = []
        for (index, view) in helper.orderedTextFields.enumerate() {
            var text: String = ""
            let textField = view as? UITextField
            text = textField?.text ?? ""
            if text.length() <= 0 {
                let textView = view as? UITextView
                text = textView?.text ?? ""
            }
            
            if !helper.validateItemAtIndex(index, text: text) {
                indexes.append(index)
            }
        }
        
        if indexes.count > 0 {
            return indexes
        } else {
            return nil
        }
    }
    
    /**
     This will cycle throught every input field, on taping next button of keyboard.
     If done button is tapped, submitButtonTapped is called for handling it.
     */
    func updateResponderLoginState() {
        if let currentFirstResponder = currentFirstResponder {
            
            if let textField = currentFirstResponder as? UITextField where textField.returnKeyType == .Done {
                textField.resignFirstResponder()
                helper.submitButtonTapped()
                return
            }
            
            if let textView = currentFirstResponder as? UITextView where textView.returnKeyType == .Done {
                textView.resignFirstResponder()
                helper.submitButtonTapped()
                return
            }
            
            let index = helper.orderedTextFields.indexOf(currentFirstResponder)
            if let index = index {
                let nextIndex = (index + 1) < helper.orderedTextFields.count ? index + 1 : 0
                helper.orderedTextFields[nextIndex].becomeFirstResponder()
            }
        }
    }
    
    /**
     Put bottom inset for scrollview, depening on keyboard size.
     
     - Parameter notification: pass UIKeyboardDidShowNotification object
     */
    func handleKeyboardAppearence(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardSize = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
                adjustInsetForKeyboardHeight(keyboardOfHeight: keyboardSize.height, textField: currentFirstResponder)
            }
        }
    }
    
    /**
     Remove bottom inset from scrollview.
     
     - Parameter notification: pass UIKeyboardDidHideNotification object
     */
    func handleKeyboardDisappearance(notification: NSNotification) {
        adjustInsetForKeyboardHeight(keyboardOfHeight: 0, textField: nil)
    }
    
    
    func handleTapGesture(gesture: UITapGestureRecognizer) {
        currentFirstResponder?.resignFirstResponder()
    }

}

//MARK: Scroll view Inset adjustment methods
private extension KeyboardHandler {
    
    func addKeyboardNotificationObserver() {
        //Add observer to get notification about keyboard.
        NSNotificationCenter.registerForKeyboardNotificationObject(self, appearenceSelector: #selector(KeyboardHandler.handleKeyboardAppearence(_:)), disappearenceSelector: #selector(KeyboardHandler.handleKeyboardDisappearance(_:)))
    }
    
    func removeKeyboardNotificationObserver() {
        NSNotificationCenter.registerForKeyboardNotificationObject(self)
    }
    
    func adjustInsetForKeyboardHeight(keyboardOfHeight height: CGFloat, textField: UIView?) {
        
        addBottomScrollInset(height)
        
        //scroll to make that text field visible
        if let textField = textField where height != 0 {
            let textFieldBottomY = textField.convertPoint(CGPointMake(0, textField.bounds.origin.y), toView: nil).y
            let keyboardTopY = UIApplication.currentSize().height - height;
            if keyboardTopY < textFieldBottomY {
                helper.rootContainerScrollView.scrollRectToVisible(textField.frame, animated: true)
            }
        }
    }
    
    func addBottomScrollInset(inset: CGFloat) {
        UIView.animateWithDuration(0.4, animations: { [weak self] () -> Void in
            self?.helper.rootContainerScrollView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: inset, right: 0)
            self?.helper.rootContainerScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: inset, right: 0)
            }, completion: nil)
    }
}

//MARK: Keyboard return type setting methods
private extension KeyboardHandler {
    
    func returnKeyForKeyboard() -> UIReturnKeyType {
        
        var count = 0
        if let orderedTextFields = helper.orderedTextFields {
            for view in orderedTextFields {
                if !validateView(view) {
                    count += 1
                }
            }
        }
        
        if count == 1 {
            return helper.doneButtonType()
        }
        
        return .Next
    }
    
    func validateView(view: UIView) -> Bool {
        if let textfield = view as? UITextField {
            return textfield.text?.characters.count > 0
        } else if let textView = view as? UITextView {
            return textView.text?.characters.count > 0
        } else {
            return false
        }
    }
}

extension KeyboardHandler: UITextFieldDelegate {
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        return helper.textFieldDelegate?.textField?(textField, shouldChangeCharactersInRange: range, replacementString: string) ?? true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        helper.cleanupErrorMessageIfExist()
        helper.textFieldDelegate?.textFieldDidBeginEditing?(textField)
        textField.returnKeyType = returnKeyForKeyboard()
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        helper.textFieldDelegate?.textFieldDidEndEditing?(textField)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        updateResponderLoginState()
        return helper.textFieldDelegate?.textFieldShouldReturn?(textField) ?? true
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        currentFirstResponder = textField
        return helper.textFieldDelegate?.textFieldShouldBeginEditing?(textField) ?? true
    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        return helper.textFieldDelegate?.textFieldShouldClear?(textField) ?? true
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        return helper.textFieldDelegate?.textFieldShouldEndEditing?(textField) ?? true
    }
}

extension KeyboardHandler: UITextViewDelegate {
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        return helper.textViewDelegate?.textView?(textView, shouldChangeTextInRange: range, replacementText: text) ?? true
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        helper.cleanupErrorMessageIfExist()
        textView.returnKeyType = returnKeyForKeyboard()
        helper.textViewDelegate?.textViewDidBeginEditing?(textView)
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        helper.textViewDelegate?.textViewDidEndEditing?(textView)
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        updateResponderLoginState()
        return helper.textViewDelegate?.textViewShouldEndEditing?(textView) ?? true
    }
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        currentFirstResponder = textView
        return helper.textViewDelegate?.textViewShouldBeginEditing?(textView) ?? true
    }
    
    func textViewDidChange(textView: UITextView) {
        helper.textViewDelegate?.textViewDidChange?(textView)
    }
    
    func textViewDidChangeSelection(textView: UITextView) {
        helper.textViewDelegate?.textViewDidChangeSelection?(textView)
    }
    
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        return helper.textViewDelegate?.textView?(textView, shouldInteractWithURL: URL, inRange: characterRange) ?? true
    }
    
    func textView(textView: UITextView, shouldInteractWithTextAttachment textAttachment: NSTextAttachment, inRange characterRange: NSRange) -> Bool {
        return helper.textViewDelegate?.textView?(textView, shouldInteractWithTextAttachment: textAttachment, inRange: characterRange) ?? true
    }
}
