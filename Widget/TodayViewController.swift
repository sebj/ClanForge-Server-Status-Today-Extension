
//  TodayViewController.swift

//  Created by Sebastian Jachec on 13/12/2015.
//  Copyright © 2015 Sebastian Jachec. All rights reserved.

import Cocoa
import NotificationCenter

//http://stackoverflow.com/a/26725096/447697

class TodayViewController: NSViewController, NCWidgetProviding, NCWidgetListViewDelegate, NSXMLParserDelegate {
    
    let sharedUD = NSUserDefaults(suiteName: UDSuiteName)
    var settingsChanged = false
    
    @IBOutlet var listViewController: NCWidgetListViewController!
    var editViewController: EditViewController?
    @IBOutlet var loadingView: NSView!
    @IBOutlet var textField: NSTextField!
    
    var currentView: NSView!
    var loading: Bool = false
    
    var refreshCompletionHandler: ((NCUpdateResult) -> Void)!
    
    var refreshTimer = NSTimer()
    let refreshInterval:Double = 60
    let timerTolerance:Double = 15
    
    let baseURL = "https://clanforge.multiplay.co.uk/public/servers.pl?event=Online;opt=ServersXmlList;accountserviceid="
    
    
    // MARK: - NSViewController

    override var nibName: String? {
        return "TodayViewController"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentView = loadingView
        
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(refreshInterval, target: self, selector: "refreshData", userInfo: nil, repeats: true)
        refreshTimer.tolerance = timerTolerance
        NSRunLoop.mainRunLoop().addTimer(refreshTimer, forMode: NSRunLoopCommonModes)
        
        self.listViewController.contents = []
        
        let lastRefresh: NSDate? = sharedUD?.objectForKey(UDLastRefreshKey) as! NSDate?
        if let lastRefreshDate = lastRefresh {
            
            let now = NSDate()
            let difference = now.timeIntervalSinceDate(lastRefreshDate)
            
            if difference <= ((refreshInterval+timerTolerance)*1.2) {
                restoreCachedData()
            }
        }
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
    
    func restoreCachedData() {
        let cachedData: NSData? = sharedUD?.dataForKey(UDCacheKey)
        
        if let cache = cachedData {
            debugOnlyPrint("Restoring cached data")
            
            let cachedServerList: Array<ServerObject> = NSKeyedUnarchiver.unarchiveObjectWithData(cache) as! Array<ServerObject>
            listViewController.contents = cachedServerList
        }
    }
    
    let setAccountIDMessage = "Set a valid Account ID – click (ℹ︎) to edit settings."

    func refreshData() {
        let accountID = sharedUD?.stringForKey(UDAccountIDKey)
        
        if validAccountID(accountID) {
            loading = true
            textField.stringValue = "Loading..."
            
            replaceCurrentViewWith(loadingView)
            
            let url = NSURL(string: "\(baseURL)\(accountID!)")!
            
            let session = NSURLSession.sharedSession()
            let request = NSURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 15)
            
            session.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                
                if let err = error {
                    self.refreshCompletionHandler(.Failed)
                    
                    print("Error loading: \(err)")
                    self.textField.stringValue = "Failed to refresh"
                    
                    self.performSelectorOnMainThread(Selector("restoreCachedData"), withObject: nil, waitUntilDone: false)
                    
                } else if let d = data {
                    
                    debugOnlyPrint("Refreshed")
                    
                    self.parseData(d)
                }
            }).resume()
            
        } else {
            textField.stringValue = setAccountIDMessage
        }
    }
    
    
    // MARK: Parsing
    func parseData(data: NSData) {
        let parser = NSXMLParser(data: data)
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
            let server = ServerObject(type: attributeDict["type"], name: nil, address: attributeDict["address"], status: attributeDict["status"], players: 0, maxPlayers: 0)
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
        
        if let server = currentObject where elementName == startedElementName {
            
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
        currentString = ""
    }
    
    func parserDidEndDocument(parser: NSXMLParser) {
        performSelectorOnMainThread(Selector("updateServerList:"), withObject: self.tempServerList, waitUntilDone: false)
    }
    
    
    func updateServerList(newServerList: Array<ServerObject>) {
        //debugOnlyPrint(newServerList)
        
        loading = false
        
        listViewController.contents = newServerList
        
        tempServerList = []
        
        replaceCurrentViewWith(listViewController.view)
        
        //Update User Defaults
        //Last refresh time
        sharedUD?.setObject(NSDate(), forKey: UDLastRefreshKey)
        
        //Cache server list array
        let data = NSKeyedArchiver.archivedDataWithRootObject(listViewController.contents)
        sharedUD?.setObject(data, forKey: UDCacheKey)
        
        
        refreshCompletionHandler(.NewData)
    }

    
    // MARK: - NCWidgetProviding

    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Refresh the widget's contents in preparation for a snapshot.
        // Call the completion handler block after the widget's contents have been
        // refreshed. Pass NCUpdateResultNoData to indicate that nothing has changed
        // or NCUpdateResultNewData to indicate that there is new data since the
        // last invocation of this method.
        refreshCompletionHandler = completionHandler
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
        
        if !loading {
            
            if editViewController == nil {
                let newController = EditViewController()
                newController.todayController = self
                editViewController = newController
            }
            
            replaceCurrentViewWith(editViewController!.view)
        }
    }
    
    func widgetDidEndEditing() {
        if (settingsChanged) {
            
            settingsChanged = false
            refreshData()
            
        } else {
            
            if let accountID = sharedUD?.stringForKey(UDAccountIDKey) where validAccountID(accountID) {
                replaceCurrentViewWith(listViewController.view)
                
            } else {
                replaceCurrentViewWith(loadingView)
            }
        }
        
        editViewController = nil
    }

    
    // MARK: - NCWidgetListViewDelegate

    func widgetList(list: NCWidgetListViewController!, viewControllerForRow row: Int) -> NSViewController! {
        // Return a new view controller subclass for displaying an item of widget
        // content. The NCWidgetListViewController will set the representedObject
        // of this view controller to one of the objects in its contents array.
        return ListRowViewController()
    }

    func widgetList(list: NCWidgetListViewController!, shouldReorderRow row: Int) -> Bool {
        return false
    }

    func widgetList(list: NCWidgetListViewController!, shouldRemoveRow row: Int) -> Bool {
        return false
    }

}
