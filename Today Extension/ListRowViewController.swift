
//  ListRowViewController.swift

//  Created by Sebastian Jachec on 13/12/2015.
//  Copyright © 2016 Sebastian Jachec. All rights reserved.

import Cocoa

class IndicatorView : NSView {
    var up: Bool = true
    
    let greenColor = NSColor(calibratedRed:0.325, green:0.843, blue:0.302, alpha:1)
    let redColor = NSColor(calibratedRed:1, green:0.247, blue:0.251, alpha:1)
    
    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(ovalIn: self.bounds)
        
        let color = up ? greenColor : redColor
        color.setFill()
        path.fill()
    }
}

class ListRowViewController: NSViewController {
    
    @IBOutlet var statusIndicatorView: IndicatorView!

    override var nibName: String? {
        return "ListRowViewController"
    }

    override func loadView() {
        super.loadView()
        
        let server = self.representedObject as? ServerObject
        
        if let serverStatus = server?.status {
            statusIndicatorView!.up = (serverStatus.caseInsensitiveCompare("UP") == ComparisonResult.orderedSame)
        }
    }

}
