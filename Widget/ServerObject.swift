//
//  ServerObject.swift
//  ClanForge Status
//
//  Created by Sebastian Jachec on 13/12/2015.
//  Copyright © 2015 Sebastian Jachec. All rights reserved.
//

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
            type: decoder.decodeObjectForKey("type") as? String,
            name: decoder.decodeObjectForKey("name") as? String,
            address: decoder.decodeObjectForKey("address") as? String,
            status: decoder.decodeObjectForKey("status") as? String,
            players: decoder.decodeIntegerForKey("players"),
            maxPlayers: decoder.decodeIntegerForKey("maxPlayers")
        )
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(type, forKey: "type")
        coder.encodeObject(name, forKey: "name")
        coder.encodeObject(address, forKey: "address")
        coder.encodeObject(status, forKey: "status")
        coder.encodeInteger(players, forKey: "players")
        coder.encodeInteger(maxPlayers, forKey: "maxPlayers")
    }
}
