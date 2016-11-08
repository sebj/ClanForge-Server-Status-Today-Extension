
//  Utils.swift

//  Created by Sebastian Jachec on 14/12/2015.
//  Copyright © 2016 Sebastian Jachec. All rights reserved.

import Foundation


//User Defaults
let UDSuiteName = "group.me.sebj.ClanForge-Server-Status"

let UDAccountIDKey = "accountID"
let UDCacheKey = "dataCache"
let UDLastRefreshKey = "lastRefresh"


func debugOnlyPrint(_ items: Any...) {
    #if DEBUG
        print(items)
    #endif
}

func validAccountID(_ accountID: String?) -> Bool {
    if let a = accountID, let _ = Int(a), a.characters.count == 6 {
        return true
    }
    
    return false
}
