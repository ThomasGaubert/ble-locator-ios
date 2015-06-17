//
//  BeaconIO.swift
//  BLE Locator
//

import Foundation
import SwiftyJSON

class BeaconIO {
    
    static let fileName = "beacons.json"
    static var seenBeacons = [String: SeenBeacon]();
    
    /**
    Load all previously seen beacons from filesystem.
    
    **Note:** Must call `loadBeacons()` before `getSeenBeacons()`, `getSeenBeacon()`, and `putSeenBeacon()`.
    */
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
    
    /**
    Save all previously seen beacons to filesystem.
    */
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
    
    /**
    Get `NSDictionary` of all previously seen beacons.
    
    :returns: `NSDictionary` of all previously seen beacons.
    */
    static func getSeenBeacons() -> [String: SeenBeacon] {
        return seenBeacons
    }
    
    /**
    Get `SeenBeacon` corresponding to given `key`.
    
    :param: key Key used to lookup a specific `SeenBeacon`.
    
    :returns: `SeenBeacon` corresponding to given `key`.
    */
    static func getSeenBeacon(key: String) -> SeenBeacon {
        return seenBeacons[key]!
    }
    
    /**
    Store `SeenBeacon` corresponding to given `key`.
    
    :param: key Key used to lookup a given `SeenBeacon`.
    :param: beacon `SeenBeacon` to store corresponding to given `key`.
    */
    static func putSeenBeacon(key: String, beacon: SeenBeacon) {
        seenBeacons[key] = beacon
    }
    
    /**
    Get `SeenBeacon` corresponding to given `key`.
    
    **Note:** Automatically calls `saveBeacons()`.
    */
    static func reset() {
        seenBeacons.removeAll(keepCapacity: false)
        saveBeacons()
    }
    
}