
//  Utils.swift

//  Created by Sebastian Jachec on 14/12/2015.
//  Copyright © 2015 Sebastian Jachec. All rights reserved.

import Foundation


//User Defaults
let UDSuiteName = "group.me.sebj.ClanForge-Server-Status"

let UDAccountIDKey = "accountID"
let UDCacheKey = "dataCache"
let UDLastRefreshKey = "lastRefresh"


func debugOnlyPrint(items: Any...) {
    #if DEBUG
        print(items)
    #endif
}

func validAccountID(accountID: String?) -> Bool {
    if let a = accountID, _ = Int(a) where a.characters.count == 6 {
        return true
    }
    
    return false
}