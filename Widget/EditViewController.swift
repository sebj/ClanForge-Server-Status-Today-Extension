//
//  EditViewController.swift
//  ClanForge Status
//
//  Created by Sebastian Jachec on 16/12/2015.
//  Copyright © 2015 Sebastian Jachec. All rights reserved.
//

import Cocoa

class EditViewController: NSViewController {
    
    var todayController: TodayViewController!
    @IBOutlet weak var accountIDField: NSTextField!
    
    override var nibName: String? {
        return "EditViewController"
    }
    
    override func viewDidLoad() {
        let sharedUD = NSUserDefaults(suiteName: UDSuiteName)
        
        if let id = sharedUD?.stringForKey(UDAccountIDKey) {
            accountIDField.stringValue = id
        }
    }
    
    override func controlTextDidChange(aNotification: NSNotification) {
        let sharedUD = NSUserDefaults(suiteName: UDSuiteName)
        
        //TODO: Sanitise value
        sharedUD?.setValue(accountIDField.stringValue, forKey: UDAccountIDKey)
        
        sharedUD?.synchronize()
        
        todayController.settingsChanged = true
    }
    
}