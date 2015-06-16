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
    
    init() {
        validBeacons = []
        tracking = false
        beaconCount = 0
        lastNotifText = ""
    }
    
    func getValidBeacons() -> [SeenBeacon] {
        return validBeacons
    }
    
    func setTracking(track: Bool) {
        tracking = track
        
        if(!tracking) {
            BeaconIO.saveBeacons()
        }
    }
    
    func isTracking() -> Bool {
        return tracking
    }
    
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
    func getName(key: String) -> String {
        let seenBeacon = BeaconIO.getSeenBeacon(key)
        if seenBeacon.userName.rangeOfString("\u{2063}") == nil {
            return seenBeacon.userName
        }
        
        return seenBeacon.btName
    }
    
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