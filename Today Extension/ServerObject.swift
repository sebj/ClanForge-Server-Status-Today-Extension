
//  ServerObject.swift

//  Created by Sebastian Jachec on 13/12/2015.
//  Copyright © 2016 Sebastian Jachec. All rights reserved.

import Foundation

class ServerObject : NSObject, NSCoding {
    var type: String?
    var name: String?
    var address: String?
    var status: String?
    var players: Int = 0
    var maxPlayers: Int = 0
    
    init(type: String?, name: String?, address: String?, status: String?, players: Int, maxPlayers: Int) {
        super.init()
        
        self.type = type
        self.name = name
        self.address = address
        self.status = status
        self.players = players
        self.maxPlayers = maxPlayers
    }
    
    override var description: String {
        
        var desc = "<ServerObject:"
        
        if let t = type {
            desc += " type='\(t)\'"
        }
        if let n = name {
            desc += " name='\(n)'"
        }
        if let a = address {
            desc += " address='\(a)'"
        }
        if let s = status {
            desc += " status='\(s)'"
        }
        
        
        return desc+" players=\(players) maxPlayers=\(maxPlayers)>"
    }
    
    // MARK: NSCoding
    
    required convenience init(coder decoder: NSCoder) {
        self.init(
            type: decoder.decodeObject(forKey: "type") as? String,
            name: decoder.decodeObject(forKey: "name") as? String,
            address: decoder.decodeObject(forKey: "address") as? String,
            status: decoder.decodeObject(forKey: "status") as? String,
            players: decoder.decodeInteger(forKey: "players"),
            maxPlayers: decoder.decodeInteger(forKey: "maxPlayers")
        )
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(type, forKey: "type")
        coder.encode(name, forKey: "name")
        coder.encode(address, forKey: "address")
        coder.encode(status, forKey: "status")
        coder.encode(players, forKey: "players")
        coder.encode(maxPlayers, forKey: "maxPlayers")
    }
}
