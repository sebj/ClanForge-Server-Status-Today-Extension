
//  AppDelegate.swift

//  Created by Sebastian Jachec on 13/12/2015.
//  Copyright © 2016 Sebastian Jachec. All rights reserved.

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet var mainWindow: NSWindow!
    
    @IBOutlet var settingsView: NSView!
    @IBOutlet var accountIDField: NSTextField!
    
    @IBOutlet var activateView: NSView!
    
    let sharedUD = UserDefaults(suiteName: UDSuiteName)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        mainWindow.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
        showSection(1)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true;
    }
    
    @IBAction func showSectionView(_ sender: AnyObject) {
        let index = mainWindow.toolbar?.items.index(of: sender as! NSToolbarItem)
        showSection(index!)
    }
    
    func showSection(_ index: Int) {
        if index == 1 {
            mainWindow.contentView = activateView
            mainWindow.title = "Activate"
            
        } else {
            mainWindow.contentView = settingsView
            mainWindow.title = "Preferences"
            
            if let id = sharedUD?.string(forKey: UDAccountIDKey) {
                accountIDField.stringValue = id
            }
        }
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        let accountIDFieldString = accountIDField.stringValue
        
        if validAccountID(accountIDFieldString) {
            sharedUD?.setValue(accountIDFieldString, forKey: UDAccountIDKey)
            sharedUD?.synchronize()
        }
    }
    
    @IBAction func openSystemPreferencesPane(_ sender: NSButton) {
        
        let fileURL = URL(fileURLWithPath: "/System/Library/PreferencePanes/Extensions.prefPane")
        NSWorkspace.shared().open(fileURL)
    }
    
    @IBAction func openClanForge(_ sender: NSButton) {
        
        let URL = Foundation.URL(string: "https://clanforge.multiplay.co.uk/")
        NSWorkspace.shared().open(URL!)
    }
}

