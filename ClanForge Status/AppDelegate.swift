
//  AppDelegate.swift

//  Created by Sebastian Jachec on 13/12/2015.
//  Copyright © 2015 Sebastian Jachec. All rights reserved.

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet var mainWindow: NSWindow!
    
    @IBAction func openSystemPreferencesPane(sender: NSButton) {
        
        let fileURL = NSURL(fileURLWithPath: "/System/Library/PreferencePanes/Extensions.prefPane")
        NSWorkspace.sharedWorkspace().openURL(fileURL)
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        mainWindow.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
    }
}

