
//  ListRowViewController.swift

//  Created by Sebastian Jachec on 13/12/2015.
//  Copyright © 2015 Sebastian Jachec. All rights reserved.

import Cocoa

class StatusView : NSView {
    
    var delegate: AnyObject?
    var up: Bool = true
    
    override func drawRect(dirtyRect: NSRect) {
        let path = NSBezierPath(ovalInRect: self.bounds)
        
        var color = NSColor.greenColor()
        if up {
            color = NSColor.redColor()
        }
        
        color.setFill()
        path.fill()
    }
    
    override func mouseUp(theEvent: NSEvent) {
        Swift.print("clickk")
        if let d = delegate {
            if d.respondsToSelector(Selector("handleClick")) {
                d.handleClick()
            }
        }
    }
}

class ListRowViewController: NSViewController {
    
    @IBOutlet var statusView: StatusView?

    override var nibName: String? {
        return "ListRowViewController"
    }
    
    func handleClick() {
        print("Click2!")
    }
    
    @IBAction func click(sender: AnyObject) {
        print("click!")
        self.extensionContext?.openURL(NSURL(string:"clanforgeserverstatus://click")!, completionHandler: nil)
    }

    override func loadView() {
        super.loadView()

        // Insert code here to customize the view
        let server = self.representedObject as? ServerObject
        
        statusView!.up = (server?.status == "UP")
        
        /*print(self.representedObject)
        
        if let theServer = server {
            print("server isn't nil!")
            print("desc:"+theServer.description)
        
            if let name = theServer.name {
                nameField?.stringValue = name
            }
        
        
        } else {
            print("server is nil?")
        }*/
    }

}
