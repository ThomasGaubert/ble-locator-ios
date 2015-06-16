//
//  BeaconIO.swift
//  BLE Locator
//

import Foundation

class BeaconIO {
    
    static let fileName = "beacons.json"
    static var seenBeacons = [String: SeenBeacon]();
    
    static func loadBeacons() {
        if let dirs : [String] = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true) as? [String] {
            let dir = dirs[0]
            let path = dir.stringByAppendingPathComponent(fileName)
            if(!NSFileManager.defaultManager().fileExistsAtPath(path)) {
                saveBeacons();
            }
            
            let data = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)
            
            if let dataFromString = data!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                let json = JSON(data: dataFromString)
                
                println("Data loaded: \n\(json)")
                
                for (key: String, subJson: JSON) in json {
                    seenBeacons[key] = SeenBeacon(uuid: key, json: subJson)
                }
            }
        }
    }
    
    static func saveBeacons() {
        if let dirs : [String] = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true) as? [String] {
            let dir = dirs[0]
            let path = dir.stringByAppendingPathComponent(fileName)
            
            var jsonData = JSON("")
            var dict = [String: Dictionary<String, AnyObject>]();
            
            for (key, value) in seenBeacons {
                dict[key] = value.getJsonObject().dictionaryObject
            }
            
            jsonData = JSON(dict)
            println("Data saved: \n\(jsonData)")
            
            jsonData.rawString(encoding: NSUTF8StringEncoding, options: nil)!.writeToFile(path, atomically: false, encoding: NSUTF8StringEncoding, error: nil)
        }
    }
    
    static func getSeenBeacons() -> [String: SeenBeacon] {
        return seenBeacons
    }
    
    static func getSeenBeacon(key: String) -> SeenBeacon {
        return seenBeacons[key]!
    }
    
    static func putSeenBeacon(key: String, beacon: SeenBeacon) {
        seenBeacons[key] = beacon
    }
    
    static func reset() {
        seenBeacons.removeAll(keepCapacity: false)
        saveBeacons()
    }
    
}