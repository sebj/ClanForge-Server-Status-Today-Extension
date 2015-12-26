
//  EditViewController.swift

//  Created by Sebastian Jachec on 16/12/2015.
//  Copyright © 2015 Sebastian Jachec. All rights reserved.

import Cocoa

class EditViewController: NSViewController {
    
    let sharedUD = NSUserDefaults(suiteName: UDSuiteName)
    
    var todayController: TodayViewController!
    @IBOutlet weak var accountIDField: NSTextField!
    
    var accountIDString: String?
    
    override var nibName: String? {
        return "EditViewController"
    }
    
    override func viewDidLoad() {
        
        if let id = sharedUD?.stringForKey(UDAccountIDKey) {
            accountIDField.stringValue = id
        }
    }
    
    override func viewWillDisappear() {
        let accountIDFieldString = accountIDField.stringValue
        
        if validAccountID(accountIDFieldString) {
            
            sharedUD?.setValue(accountIDFieldString, forKey: UDAccountIDKey)
            sharedUD?.synchronize()
            
            todayController.settingsChanged = true
            
        } else {
            //Invalid account ID
            NSBeep()
        }
    }
    
}