
//  TodayViewController.swift

//  Created by Sebastian Jachec on 13/12/2015.
//  Copyright © 2015 Sebastian Jachec. All rights reserved.

import Cocoa
import NotificationCenter

class TodayViewController: NSViewController, NCWidgetProviding, NCWidgetListViewDelegate, NSXMLParserDelegate {
    
    var settingsChanged = false
    
    @IBOutlet var listViewController: NCWidgetListViewController!
    var editViewController: EditViewController?
    @IBOutlet var loadingView: NSView!
    @IBOutlet var textField: NSTextField!
    
    var currentView: NSView!
    
    var timer = NSTimer()
    
    // MARK: - NSViewController

    override var nibName: String? {
        return "TodayViewController"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentView = loadingView
        //editViewController.todayController = self
        
        timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: "refreshData", userInfo: nil, repeats: true)
        timer.tolerance = 15
        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
        
        self.listViewController.contents = []
    }
    
    func refreshData() {
        let sharedUD = NSUserDefaults(suiteName: UDSuiteName)
        
        let accountID = sharedUD?.stringForKey(UDAccountIDKey)
        
        if let ID = accountID {
            
            if ID.characters.count == 0 {
                //Non-nil accountID, but empty e.g. ""
                textField.stringValue = "Set a valid Account ID – edit this widget."
                
                //widgetDidBeginEditing()
                
            } else {
                
                textField.stringValue = "Loading..."
                
                replaceCurrentViewWith(loadingView)
                
                let url = NSURL(string: "https://clanforge.multiplay.co.uk/public/servers.pl?event=Online;opt=ServersXmlList;accountserviceid=\(ID)")!
                
                let session = NSURLSession.sharedSession()
                let request = NSURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 15)
                
                session.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                    
                    if let err = error {
                        print("Error: \(err)")
                        self.textField.stringValue = "Failed to refresh"
                        
                    } else if let d = data {
                        self.parseData(d)
                    }
                }).resume()
            }
            
        } else {
            textField.stringValue = "Set a valid Account ID – edit this widget."
            
            //widgetDidBeginEditing()
        }
    }
    
    // MARK: Parsing
    func parseData(data: NSData) {
        let parser = NSXMLParser(data: data)
        parser.shouldProcessNamespaces = true
        parser.externalEntityResolvingPolicy = .ResolveExternalEntitiesAlways
        
        parser.delegate = self
        parser.parse()
    }
    
    var tempServerList: Array<ServerObject> = []
    var currentObject: ServerObject?
    var startedElementName: String?
    var currentString: String = ""
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        startedElementName = elementName
        
        if elementName == "server" {
            let server = ServerObject()
            server.address = attributeDict["address"]
            server.status = attributeDict["status"]
            server.type = attributeDict["type"]
            currentObject = server
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        
        if string.characters.count > 0 {
            
            if ["name", "numplayers", "maxplayers"].contains(startedElementName!) {
                currentString += string
            }
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if elementName == startedElementName {
            
            if let server = currentObject {
                
                let tidiedString = currentString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                
                switch elementName {
                    case "name":
                        server.name = currentString
                        break
                    
                    case "numplayers":
                        server.players = Int(tidiedString)!
                        break
                    
                    case "maxplayers":
                        server.maxPlayers = Int(tidiedString)!
                    
                        //Add to content array
                        tempServerList.append(server)
                        
                        currentObject = nil
                        
                        break
                    
                    default:
                        break
                }
            }
        }
        currentString = ""
    }
    
    func parserDidEndDocument(parser: NSXMLParser) {
        performSelectorOnMainThread(Selector("updateServerList:"), withObject: self.tempServerList, waitUntilDone: false)
    }
    
    func updateServerList(newServerList: Array<ServerObject>) {
        //print("Finished loading")
        listViewController.contents = newServerList
        
        tempServerList = []
        
        replaceCurrentViewWith(listViewController.view)
    }

    // MARK: - NCWidgetProviding

    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Refresh the widget's contents in preparation for a snapshot.
        // Call the completion handler block after the widget's contents have been
        // refreshed. Pass NCUpdateResultNoData to indicate that nothing has changed
        // or NCUpdateResultNewData to indicate that there is new data since the
        // last invocation of this method.
        completionHandler(.NewData)
        refreshData()
    }

    func widgetMarginInsetsForProposedMarginInsets(var defaultMarginInset: NSEdgeInsets) -> NSEdgeInsets {
        defaultMarginInset.left = 0
        defaultMarginInset.top = 0
        defaultMarginInset.bottom = 0
        return defaultMarginInset
    }

    var widgetAllowsEditing: Bool {
        return true
    }
    
    func widgetDidBeginEditing() {
        if editViewController == nil {
            let newController = EditViewController()
            newController.todayController = self
            editViewController = newController
        }
        
        replaceCurrentViewWith(editViewController!.view)
    }
    
    func widgetDidEndEditing() {
        if (settingsChanged) {
            
            settingsChanged = false
            refreshData()
            
        } else {
            let sharedUD = NSUserDefaults(suiteName: UDSuiteName)
            
            let accountID = sharedUD?.stringForKey(UDAccountIDKey)
            
            if accountID == nil || accountID!.characters.count == 0 {
                replaceCurrentViewWith(loadingView)
                
            } else {
                replaceCurrentViewWith(listViewController.view)
            }
        }
        
        editViewController = nil
    }
    
    //Delay solution for flickering (i)/Done button bug from http://stackoverflow.com/a/26679638/447697
    let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
    
    func replaceCurrentViewWith(newView: NSView) {
        
        if currentView != newView {
                
            newView.translatesAutoresizingMaskIntoConstraints = false
            
            let container = view
                
            container.replaceSubview(currentView, with: newView)
            
            let viewsDict = ["newView" : newView]
            container.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[newView]|", options:NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDict))
            container.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[newView]|", options:NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDict))
            
            self.currentView = newView
        }
    }

    // MARK: - NCWidgetListViewDelegate

    func widgetList(list: NCWidgetListViewController!, viewControllerForRow row: Int) -> NSViewController! {
        // Return a new view controller subclass for displaying an item of widget
        // content. The NCWidgetListViewController will set the representedObject
        // of this view controller to one of the objects in its contents array.
        return ListRowViewController()
    }

    func widgetList(list: NCWidgetListViewController!, shouldReorderRow row: Int) -> Bool {
        // Return true to allow the item to be reordered in the list by the user.
        return false
    }

    func widgetList(list: NCWidgetListViewController!, shouldRemoveRow row: Int) -> Bool {
        // Return true to allow the item to be removed from the list by the user.
        return false
    }

}
