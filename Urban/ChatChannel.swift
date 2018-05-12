//
//  ChatChannel.swift
//  Urban
//
//  Created by Kangtle on 8/18/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import Foundation

class ChatChannel{
    var id: String!
    var opponent: Opponent!
    var lastMessage: Message!
    

    init(channelId: String) {
        self.id = channelId
    }
}
