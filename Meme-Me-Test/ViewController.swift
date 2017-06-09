//
//  ViewController.swift
//  Meme-Me-Test
//
//  Created by JFK on 6/5/17.
//  Copyright © 2017 Jonathan Kaufman. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var imageViewJK: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var topText: UITextField!
    @IBOutlet weak var bottomText: UITextField!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var toolbarBottom: UIToolbar!

    let notificationName = Notification.Name("NotificationIdentifier")
    let pickerControllerJK = UIImagePickerController()
    let memeTextAttributes: [String : Any] = [
        NSStrokeColorAttributeName: UIColor.black,
        NSForegroundColorAttributeName: UIColor.white,
        NSFontAttributeName: UIFont(name: "Impact", size: 40)!,
            // Add choices for: 
            // Impact, Oswald, AATypewriter, AdobeGothicStd-Bold, CooperBlackStd, HoboStd, Whoa!
        NSStrokeWidthAttributeName: -3.0
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for family: String in UIFont.familyNames
        {
            print("\(family)")
            for names: String in UIFont.fontNames(forFamilyName: family)
            {
                print("== \(names)")
            }
        }
        
        pickerControllerJK.delegate = self
        
        topText.delegate = self
        topText.text = "TOP"
        topText.defaultTextAttributes = memeTextAttributes
        topText.textAlignment = .center
        
        bottomText.delegate = self
        bottomText.text = "BOTTOM"
        bottomText.defaultTextAttributes = memeTextAttributes
        bottomText.textAlignment = .center
        
        shareButton.isEnabled = false
        
        toolbarBottom.barTintColor = UIColor(hexString: "#4097A3")
        toolbarBottom.sizeToFit()
    }
    
    // MARK - Standard methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    // MARK - Image picker
    @IBAction func pickImage(_ sender: Any) {
        pickerControllerJK.sourceType = .photoLibrary
        present(pickerControllerJK, animated: true, completion: nil)
    }
    
    @IBAction func pickCameraImage(_ sender: Any) {
        pickerControllerJK.sourceType = .camera
        present(pickerControllerJK, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            print("Error")
            dismiss(animated: true, completion: nil)
            return
        }
        
        shareButton.isEnabled = true
        
        imageViewJK.contentMode = .scaleAspectFit
        imageViewJK.image = pickedImage
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        if (imageViewJK.image != nil) {
            shareButton.isEnabled = true
        } else {
            shareButton.isEnabled = false
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    // MARK - Text Field Delegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if (textField.text == "TOP" || textField.text == "BOTTOM") {
            textField.text = ""
        }
        textField.autocorrectionType = .no
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK - Keyboard slide out of the way
    func keyboardWillShow(_ notification:Notification) {
        if bottomText.isFirstResponder {
            view.frame.origin.y = getKeyboardHeight( notification ) * -1
        }
        
    }
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CG rect
        return keyboardSize.cgRectValue.height
    }
    
    func keyboardWillHide(_ notification:Notification) {
        view.frame.origin.y = 0 
    }
    
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    // MARK - Meme object
    func save(_ memedImage: UIImage) {
        let meme = Meme(topText: topText.text!, bottomText: bottomText.text!, originalImage: imageViewJK.image!, memedImageJK: generateMemedImage())
        
        /*
        let object = UIApplication.shared.delegate
        let appDelegate = object as! AppDelegate
        appDelegate.memes.append(meme)
        */
    }
    
    func generateMemedImage() -> UIImage {
        // Hide stuff
        toolbarBottom.isHidden = true
        
        // Render view to image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // Show stuff
        toolbarBottom.isHidden = false
        
        return memedImage
    }
    
    @IBAction func shareAction(_ sender: Any) {
        print("Share!")
        // generate a memed image
        let memeImage = generateMemedImage()
        // define an instance of the ActivityViewController
        // pass the ActivityViewController a memedImage as an activity item
        let controller = UIActivityViewController(activityItems: [memeImage], applicationActivities: nil)
        // present the ActivityViewController
        present(controller, animated: true, completion: nil)
        // save meme
        // dismiss ActivityViewController
        controller.completionWithItemsHandler = { (activityType: UIActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) -> Void in
            if completed == true {
                self.save(memeImage)
                print("Saved")
            }
        }
    }
    
}

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.characters.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

