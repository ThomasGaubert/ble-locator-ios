//
//  SeenBeacon.swift
//  BLE Locator
//

import Foundation
import SwiftyJSON

class SeenBeacon {
    
    var uuid = "", btName = "", userName = "BLEFinder\u{2063}", color = "#000000", distance = "0"
    var notify = false, ignore = false
    
    init(uuid: String, btName: String) {
        self.uuid = uuid
        self.btName = btName
    }
    
    init(uuid: String, json: JSON) {
        self.uuid = uuid
        
        btName = json["bt_name"].stringValue
        userName = json["user_name"].stringValue
        color = json["color"].stringValue
        notify = json["notify"].boolValue
        distance = json["distance"].stringValue
        ignore = json["ignore"].boolValue
    }
    
    func getJsonObject() -> JSON {
        let data = ["bt_name": btName,
            "user_name": userName,
            "color": color,
            "notify": notify,
            "distance": distance,
            "ignore": ignore]
        
        return JSON(data)
    }
}
