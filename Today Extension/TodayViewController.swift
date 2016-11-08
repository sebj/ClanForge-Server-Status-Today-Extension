
//  TodayViewController.swift

//  Created by Sebastian Jachec on 13/12/2015.
//  Copyright © 2016 Sebastian Jachec. All rights reserved.

import Cocoa
import NotificationCenter

//http://stackoverflow.com/a/26725096/447697

class TodayViewController: NSViewController, NCWidgetProviding, NCWidgetListViewDelegate, XMLParserDelegate {
    
    let sharedUD = UserDefaults(suiteName: UDSuiteName)
    var settingsChanged = false
    
    @IBOutlet var listViewController: NCWidgetListViewController!
    var editViewController: EditViewController?
    @IBOutlet var loadingView: NSView!
    @IBOutlet var textField: NSTextField!
    
    var currentView: NSView!
    var loading: Bool = false
    
    var refreshCompletionHandler: ((NCUpdateResult) -> Void)!
    
    var refreshTimer = Timer()
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
        
        refreshTimer = Timer.scheduledTimer(timeInterval: refreshInterval, target: self, selector: #selector(TodayViewController.refreshData), userInfo: nil, repeats: true)
        refreshTimer.tolerance = timerTolerance
        RunLoop.main.add(refreshTimer, forMode: RunLoopMode.commonModes)
        
        self.listViewController.contents = []
        
        let lastRefresh: Date? = sharedUD?.object(forKey: UDLastRefreshKey) as! Date?
        if let lastRefreshDate = lastRefresh {
            
            let now = Date()
            let difference = now.timeIntervalSince(lastRefreshDate)
            
            if difference <= ((refreshInterval+timerTolerance)*1.2) {
                restoreCachedData()
            }
        }
    }
    
    //Delay solution for flickering (i)/Done button bug from http://stackoverflow.com/a/26679638/447697
    let delay = DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    
    func replaceCurrentViewWith(_ newView: NSView) {
        
        if currentView != newView {
            
            newView.translatesAutoresizingMaskIntoConstraints = false
            
            let container = view
            
            container.replaceSubview(currentView, with: newView)
            
            let viewsDict = ["newView" : newView]
            container.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[newView]|", options:NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDict))
            container.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[newView]|", options:NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDict))
            
            self.currentView = newView
        }
    }
    
    func restoreCachedData() {
        let cachedData: Data? = sharedUD?.data(forKey: UDCacheKey)
        
        if let cache = cachedData {
            debugOnlyPrint("Restoring cached data")
            
            let cachedServerList: Array<ServerObject> = NSKeyedUnarchiver.unarchiveObject(with: cache) as! Array<ServerObject>
            listViewController.contents = cachedServerList
        }
    }
    
    let setAccountIDMessage = "Set a valid Account ID – click (ℹ︎) to edit settings."

    func refreshData() {
        let accountID = sharedUD?.string(forKey: UDAccountIDKey)
        
        if validAccountID(accountID) {
            loading = true
            textField.stringValue = "Loading..."
            
            replaceCurrentViewWith(loadingView)
            
            let url = URL(string: "\(baseURL)\(accountID!)")!
            
            let session = URLSession.shared
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 15)
            
            session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: NSError?) -> Void in
                
                if let err = error {
                    self.refreshCompletionHandler(.failed)
                    
                    print("Error loading: \(err)")
                    self.textField.stringValue = "Failed to refresh"
                    
                    self.performSelector(onMainThread: #selector(TodayViewController.restoreCachedData), with: nil, waitUntilDone: false)
                    
                } else if let d = data {
                    
                    debugOnlyPrint("Refreshed")
                    
                    self.parseData(d)
                }
            } as! (Data?, URLResponse?, Error?) -> Void).resume()
            
        } else {
            textField.stringValue = setAccountIDMessage
        }
    }
    
    
    // MARK: Parsing
    func parseData(_ data: Data) {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }
    
    var tempServerList: Array<ServerObject> = []
    var currentObject: ServerObject?
    var startedElementName: String?
    var currentString: String = ""
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        startedElementName = elementName
        
        if elementName == "server" {
            let server = ServerObject(type: attributeDict["type"], name: nil, address: attributeDict["address"], status: attributeDict["status"], players: 0, maxPlayers: 0)
            currentObject = server
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
        if string.characters.count > 0 {
            
            if ["name", "numplayers", "maxplayers"].contains(startedElementName!) {
                currentString += string
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if let server = currentObject, elementName == startedElementName {
            
            let tidiedString = currentString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
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
    
    func parserDidEndDocument(_ parser: XMLParser) {
        performSelector(onMainThread: #selector(TodayViewController.updateServerList(_:)), with: self.tempServerList, waitUntilDone: false)
    }
    
    
    func updateServerList(_ newServerList: Array<ServerObject>) {
        //debugOnlyPrint(newServerList)
        
        loading = false
        
        listViewController.contents = newServerList
        
        tempServerList = []
        
        replaceCurrentViewWith(listViewController.view)
        
        //Update User Defaults
        //Last refresh time
        sharedUD?.set(Date(), forKey: UDLastRefreshKey)
        
        //Cache server list array
        let data = NSKeyedArchiver.archivedData(withRootObject: listViewController.contents)
        sharedUD?.set(data, forKey: UDCacheKey)
        
        
        refreshCompletionHandler(.newData)
    }

    
    // MARK: - NCWidgetProviding

    func widgetPerformUpdate(completionHandler: @escaping ((NCUpdateResult) -> Void)) {
        // Refresh the widget's contents in preparation for a snapshot.
        // Call the completion handler block after the widget's contents have been
        // refreshed. Pass NCUpdateResultNoData to indicate that nothing has changed
        // or NCUpdateResultNewData to indicate that there is new data since the
        // last invocation of this method.
        refreshCompletionHandler = completionHandler
        refreshData()
    }

    func widgetMarginInsets(forProposedMarginInsets defaultMarginInset: EdgeInsets) -> EdgeInsets {
        var defaultMarginInset = defaultMarginInset
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
            
            if let accountID = sharedUD?.string(forKey: UDAccountIDKey), validAccountID(accountID) {
                replaceCurrentViewWith(listViewController.view)
                
            } else {
                replaceCurrentViewWith(loadingView)
            }
        }
        
        editViewController = nil
    }

    
    // MARK: - NCWidgetListViewDelegate

    func widgetList(_ list: NCWidgetListViewController, viewControllerForRow row: Int) -> NSViewController {
        // Return a new view controller subclass for displaying an item of widget
        // content. The NCWidgetListViewController will set the representedObject
        // of this view controller to one of the objects in its contents array.
        return ListRowViewController()
    }

    func widgetList(_ list: NCWidgetListViewController, shouldReorderRow row: Int) -> Bool {
        return false
    }

    func widgetList(_ list: NCWidgetListViewController, shouldRemoveRow row: Int) -> Bool {
        return false
    }

}
