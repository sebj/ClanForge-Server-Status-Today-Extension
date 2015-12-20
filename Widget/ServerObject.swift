//
//  ServerObject.swift
//  ClanForge Status
//
//  Created by Sebastian Jachec on 13/12/2015.
//  Copyright © 2015 Sebastian Jachec. All rights reserved.
//

import Foundation

class ServerObject : NSObject {
    var type: String?
    var name: String?
    var address: String?
    var status: String?
    var players: Int = 0
    var maxPlayers: Int = 0
    
    override var description: String {
        return "<ServerObject: name=\(name!) address=\(address) status=\(status) players=\(players) maxPlayers=\(maxPlayers)>"
    }
}
