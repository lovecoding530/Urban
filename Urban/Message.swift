//
//  Message.swift
//  Urban
//
//  Created by Kangtle on 8/18/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import Foundation

class Message {
    var senderId: String
    var message: String
    var timestamp: Int64
    var time: Date
    
    init(withDic: [String: Any]) {
        self.senderId = withDic["sender"] as? String ?? ""
        self.message = withDic["message"] as? String ?? ""
        self.timestamp = withDic["time"] as? Int64 ?? Int64(Date().timeIntervalSince1970)
        self.time = Date.init(timeIntervalSince1970: TimeInterval(self.timestamp))
    }
}
