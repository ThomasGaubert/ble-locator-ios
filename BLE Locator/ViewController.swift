//
//  ViewController.swift
//  BLE Locator
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var resetBtn: UIBarButtonItem!
    @IBOutlet weak var scanBtn: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    let locationManager = CLLocationManager()
    // Create beacon region to detect Kontakt iBeacons
    let beaconRegion:CLBeaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: "f7826da6-4fa2-4e98-8024-bc5b71e0893e")!, identifier: "Kontakt")
    let tracker = BLEDataTracker()
    var dataItems:[[String]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize tableView
        tableView.dataSource = self
        tableView.delegate = self
        
        // Update scanBtn if needed
        if(tracker.isTracking()) {
            scanBtn.title = "Stop Scan"
        }
        
        // Request permission for location access if not already granted
        if(locationManager.respondsToSelector("requestWhenInUseAuthorization")) {
            locationManager.requestWhenInUseAuthorization()
        }
        
        // Configure locationManager
        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK:  UIBarButtonItem Actions
    @IBAction func resetBtnPressed(sender: UIBarButtonItem) {
        // Present dialog confirming reset
        var ignoreAlert = UIAlertController(title: "Reset Data", message: "Are you sure you want to reset all beacon data?", preferredStyle: UIAlertControllerStyle.Alert)
        ignoreAlert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Default, handler: nil))
        ignoreAlert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Destructive, handler: { action in
            // Reset beacon data
            BeaconIO.reset()
        }))
        self.presentViewController(ignoreAlert, animated: true, completion: nil)
    }
    
    @IBAction func scanBtnPressed(sender: UIBarButtonItem) {
        // Toggle scanning
        if(!tracker.isTracking()) {
            sender.title = "Stop Scan"
            tracker.setTracking(true)
            locationManager.startRangingBeaconsInRegion(beaconRegion)
        } else {
            sender.title = "Start Scan"
            tracker.setTracking(false)
            locationManager.stopRangingBeaconsInRegion(beaconRegion)
        }
    }
    
    // MARK:  UITextFieldDelegate Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TextCell", forIndexPath: indexPath) as! UITableViewCell
        let row = indexPath.row
        
        // Display name, key, and color of beacon
        cell.textLabel?.text = self.getName(row)
        cell.detailTextLabel?.text = getKey(row)
        let color = colorFromHexString(BeaconIO.getSeenBeacon(getKey(row)).color)
        cell.textLabel?.textColor = color
        return cell
    }
    
    // MARK:  UITableViewDelegate Methods
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let cell = tableView.dequeueReusableCellWithIdentifier("TextCell", forIndexPath: indexPath) as! UITableViewCell
        let row = indexPath.row
        println("Selected cell \(row): " + (self.getName(row) as String))
        
        var alert = UIAlertController(title: self.getName(row) as String, message: nil, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: "Info", style: UIAlertActionStyle.Default, handler: { action in
            // Display beacon's JSON data
            println("Info dialog")
            var infoAlert = UIAlertController(title: self.getName(row), message: "\(BeaconIO.getSeenBeacon(self.getKey(row)).getJsonObject())", preferredStyle: .Alert)
            infoAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(infoAlert, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Rename", style: UIAlertActionStyle.Default, handler: { action in
            println("Rename dialog")
            // Display rename dialog
            var renameAlert = UIAlertController(title: "Rename Beacon", message: nil, preferredStyle: .Alert)
            renameAlert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
                if BeaconIO.getSeenBeacon(self.getKey(row)).userName.rangeOfString("\u{2063}") == nil {
                    textField.text = BeaconIO.getSeenBeacon(self.getKey(row)).userName
                }
            })
            renameAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
            renameAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
                // Save name; if blank set name using Unicode marker
                let textField = renameAlert.textFields![0] as! UITextField
                if count(textField.text) == 0 {
                    BeaconIO.getSeenBeacon(self.getKey(row)).userName = "BLEFinder\u{2063}"
                } else {
                    BeaconIO.getSeenBeacon(self.getKey(row)).userName = textField.text
                }
            }))
            self.presentViewController(renameAlert, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Color", style: UIAlertActionStyle.Default, handler: { action in
            // Display color dialog
            println("Color dialog")
            var colorAlert = UIAlertController(title: "Color Beacon", message: "Enter Hex color or choose from list.", preferredStyle: .Alert)
            colorAlert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
                textField.text = BeaconIO.getSeenBeacon(self.getKey(row)).color
            })
            colorAlert.addAction(UIAlertAction(title: "Black", style: .Default, handler: { (action) -> Void in
                self.applyColor("#000000", index: row)
            }))
            colorAlert.addAction(UIAlertAction(title: "Red", style: .Default, handler: { (action) -> Void in
                self.applyColor("#FF0000", index: row)
            }))
            colorAlert.addAction(UIAlertAction(title: "Green", style: .Default, handler: { (action) -> Void in
                self.applyColor("#00FF00", index: row)
            }))
            colorAlert.addAction(UIAlertAction(title: "Blue", style: .Default, handler: { (action) -> Void in
                self.applyColor("#0000FF", index: row)
            }))
            colorAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
            colorAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
                let textField = colorAlert.textFields![0] as! UITextField
                self.applyColor(textField.text, index: row)
            }))
            self.presentViewController(colorAlert, animated: true, completion: nil)

        }))
        alert.addAction(UIAlertAction(title: "Notify", style: UIAlertActionStyle.Default, handler: { action in
            // Display notify dialog
            println("Notify dialog")
            var notifyAlert = UIAlertController(title: "Beacon Alert", message: "Get notified if this beacon is within a distance.", preferredStyle: .Alert)
            notifyAlert.addAction(UIAlertAction(title: "Immediate", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                BeaconIO.getSeenBeacon(self.getKey(row)).distance = "1"
            }))
            notifyAlert.addAction(UIAlertAction(title: "Near", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                BeaconIO.getSeenBeacon(self.getKey(row)).distance = "2"
            }))
            notifyAlert.addAction(UIAlertAction(title: "Far", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                BeaconIO.getSeenBeacon(self.getKey(row)).distance = "3"
            }))
            notifyAlert.addAction(UIAlertAction(title: "Never", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                BeaconIO.getSeenBeacon(self.getKey(row)).distance = "0"
            }))
            self.presentViewController(notifyAlert, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Ignore", style: UIAlertActionStyle.Destructive, handler: { action in
            // Display ignore dialog
            println("Ignore dialog")
            var ignoreAlert = UIAlertController(title: "Ignore Beacon", message: "Are you sure you want to ignore this beacon?", preferredStyle: UIAlertControllerStyle.Alert)
            ignoreAlert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Default, handler: nil))
            ignoreAlert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Destructive, handler: { action in
                    // Mark beacon as ignored
                    BeaconIO.getSeenBeacon(self.getKey(row)).ignore = true
                }))
            self.presentViewController(ignoreAlert, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        // iPad specific ActionSheet configuration
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            alert.popoverPresentationController!.sourceView = cell
            alert.popoverPresentationController!.sourceRect = CGRectMake(cell.bounds.width / 2.0, cell.bounds.origin.y + (cell.bounds.height / 2.0), 1.0, 1.0)
        }
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK:  LocationManager Methods
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        // Clear tableView dataset
        dataItems = []
        
        // Process nearby beacons
        tracker.registerBeacons(beacons)
        for b in tracker.getValidBeacons() {
            dataItems.append([b.btName, b.uuid])
        }
        
        // Reload UI
        tableView.reloadData()
    }
    
    // MARK: Utility methods
    
    /**
    Get the name of a `SeenBeacon` corresponding to given `index`.
    Name will default to `btName` if `userName` is undefined.
    
    :param: index Index of `SeenBeacon` from `tableView`.
    
    :returns: Name of `SeenBeacon` corresponding to given `index`.
    */
    func getName(index: Int) -> String {
        if BeaconIO.getSeenBeacon(getKey(index)).userName.rangeOfString("\u{2063}") == nil {
            return BeaconIO.getSeenBeacon(getKey(index)).userName
        }
        
        return dataItems[index][0]
    }
    
    /**
    Get the key of a `SeenBeacon` corresponding to given `index`.
    
    :param: index Index of `SeenBeacon` from `tableView`.
    
    :returns: Key of `SeenBeacon` corresponding to given `index`.
    */
    func getKey(index: Int) -> String {
        return dataItems[index][1]
    }
    
    /**
    Get a `UIColor` corresponding to given `hex` color code.
    
    :param: hex Hex color code.
    
    :returns: `UIColor` corresponding to given `hex` color code.
    */
    func colorFromHexString(hex: String) -> UIColor {
        var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet() as NSCharacterSet).uppercaseString
        
        if (cString.hasPrefix("#")) {
            cString = cString.substringFromIndex(advance(cString.startIndex, 1))
        }
        
        if (count(cString) != 6) {
            return UIColor.blackColor()
        }
        
        var rgbValue:UInt32 = 0
        NSScanner(string: cString).scanHexInt(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    /**
    Validate hex color code and apply to `SeenBeacon` at given `index`.
    
    **Note:** Automatically appends `#` if missing from `color`.
    
    :param: color Hex color code
    :param: index Index of `SeenBeacon` from `tableView`.
    */
    func applyColor(var color: String, index: Int) {
        if Array(color)[0] != "#" {
            color = "#" + color
        }
        
        BeaconIO.getSeenBeacon(getKey(index)).color = color
    }
}