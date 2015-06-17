//
//  BLEDataTracker.swift
//  BLE Locator
//

import Foundation
import UIKit
import CoreLocation
import AudioToolbox

class BLEDataTracker {
    
    var validBeacons:[SeenBeacon]
    var tracking:Bool
    var beaconCount:Int
    var lastNotifText:String
    
    /**
    Creates `BLEDataTracker` instance.
    */
    init() {
        validBeacons = []
        tracking = false
        beaconCount = 0
        lastNotifText = ""
    }
    
    /**
    Get an array of all valid `SeenBeacon`.
    
    A `SeenBeacon` is valid if:
    
    - `ignore` is false
    
    :returns: Array of valid `SeenBeacon`.
    */
    func getValidBeacons() -> [SeenBeacon] {
        return validBeacons
    }
    
    /**
    Indicate tracking status. Will call `BeaconIO.saveBeacons()` if `track` is `false`.
    
    **Note:** Does not stop `CLLocationManager` tracking, which must be called independently.
    
    :param: track Tracking status.
    */
    func setTracking(track: Bool) {
        tracking = track
        
        if(!tracking) {
            BeaconIO.saveBeacons()
        }
    }
    
    /**
    Get current tracking status.
    
    :returns: Tracking status.
    */

    func isTracking() -> Bool {
        return tracking
    }
    
    /**
    Process an array of beacons. Processing includes:
    
    - Checking if beacon has been seen before
    - Creating a notification if necessary
    
    **Note:** Array must contain `CLBeacon` objects.
    
    :param: beacons Array of beacons to process.
    */
    func registerBeacons(beacons: [AnyObject]) {
        let knownBeacons = beacons.filter{ $0.proximity != CLProximity.Unknown }
        var firstNotifBeacon:String = ""
        validBeacons = []
        beaconCount = 0
        
        for beacon in beacons {
            let b = beacon as! CLBeacon
            let key = "\(b.proximityUUID.UUIDString)-\(b.major)-\(b.minor)"
            let seenBeacons:[String: SeenBeacon] = BeaconIO.getSeenBeacons()
            
            if(seenBeacons.indexForKey(key) != nil) {
                if(seenBeacons[key]!.ignore) {
                    println("Beacon \(key) has been seen before, but will be ignored.")
                    continue
                }
                println("Beacon \(key) has been seen before.")
                validBeacons.append(seenBeacons[key]!)
                
                if(b.proximity == CLProximity.Unknown) {
                    continue
                }
                
                if(b.proximity.rawValue <= seenBeacons[key]?.distance.toInt()) {
                    if(beaconCount == 0) {
                        firstNotifBeacon = getName(key)
                    }
                    
                    beaconCount++
                }
            } else {
                println("Just saw beacon \(key) for the first time.")
                BeaconIO.putSeenBeacon(key, beacon: SeenBeacon(uuid: key, btName: "Kontakt"))
            }
        }
        
        if beaconCount > 0 {
            if beaconCount == 1 {
                sendLocalNotificationWithMessage("\(firstNotifBeacon) is nearby.")
            } else {
                sendLocalNotificationWithMessage("\(firstNotifBeacon) and \(beaconCount - 1) other " + (beaconCount == 2 ? "beacon" : "beacons") + " are nearby.")
            }
        }
    }
    
    // MARK: Utility methods
    
    /**
    Get the name of a `SeenBeacon` corresponding to given `key`.
    Name will default to `btName` if `userName` is undefined.
    
    :param: key Key corresponding to desired `SeenBeacon`.
    
    :returns: Name of `SeenBeacon` corresponding to given `key`.
    */
    func getName(key: String) -> String {
        let seenBeacon = BeaconIO.getSeenBeacon(key)
        if seenBeacon.userName.rangeOfString("\u{2063}") == nil {
            return seenBeacon.userName
        }
        
        return seenBeacon.btName
    }
    
    /**
    Send a local notification with given `message`. Only updates if
    `message` differs from the previous message.
    
    **Note:** Clears all other notifications before creating notification.
    
    :param: message Message to display in notification.
    */
    func sendLocalNotificationWithMessage(message: String!) {
        // Only update notification if new
        if lastNotifText != message {
            // Save notification message
            lastNotifText = message
            
            // Clear previous notifications
            UIApplication.sharedApplication().applicationIconBadgeNumber = 1
            UIApplication.sharedApplication().applicationIconBadgeNumber = 0
            
            // Display notification
            let notification:UILocalNotification = UILocalNotification()
            notification.alertBody = message
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
    
}