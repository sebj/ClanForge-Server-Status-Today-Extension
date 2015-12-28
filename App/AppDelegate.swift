
//  AppDelegate.swift

//  Created by Sebastian Jachec on 13/12/2015.
//  Copyright © 2015 Sebastian Jachec. All rights reserved.

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet var mainWindow: NSWindow!
    
    @IBOutlet var settingsView: NSView!
    @IBOutlet var accountIDField: NSTextField!
    
    @IBOutlet var activateView: NSView!
    
    let sharedUD = NSUserDefaults(suiteName: UDSuiteName)

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        mainWindow.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
        showSection(1)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true;
    }
    
    @IBAction func showSectionView(sender: AnyObject) {
        let index = mainWindow.toolbar?.items.indexOf(sender as! NSToolbarItem)
        showSection(index!)
    }
    
    func showSection(index: Int) {
        if index == 1 {
            mainWindow.contentView = activateView
            mainWindow.title = "Activate"
            
        } else {
            mainWindow.contentView = settingsView
            mainWindow.title = "Preferences"
            
            if let id = sharedUD?.stringForKey(UDAccountIDKey) {
                accountIDField.stringValue = id
            }
        }
    }
    
    override func controlTextDidChange(obj: NSNotification) {
        let accountIDFieldString = accountIDField.stringValue
        
        if validAccountID(accountIDFieldString) {
            sharedUD?.setValue(accountIDFieldString, forKey: UDAccountIDKey)
            sharedUD?.synchronize()
        }
    }
    
    @IBAction func openSystemPreferencesPane(sender: NSButton) {
        
        let fileURL = NSURL(fileURLWithPath: "/System/Library/PreferencePanes/Extensions.prefPane")
        NSWorkspace.sharedWorkspace().openURL(fileURL)
    }
    
    @IBAction func openClanForge(sender: NSButton) {
        
        let URL = NSURL(string: "https://clanforge.multiplay.co.uk/")
        NSWorkspace.sharedWorkspace().openURL(URL!)
    }
}

