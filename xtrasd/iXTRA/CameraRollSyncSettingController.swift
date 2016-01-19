//
//  CameraRollSyncSettingController.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-11-24.
//  Copyright © 2015 iXTRA Technologies. All rights reserved.
//

import UIKit

class CameraRollSyncSettingController: UITableViewController {

    var selectedIndex: Int!
    var options = ["Copy", "Move"]
    var preferences: Preferences!
    let appCoreData = AppCoreData()
    
    @IBOutlet weak var autosyncSwitch: UISwitch!
    
    @IBAction func setAutosync(sender: AnyObject)
    {
        
            if self.autosyncSwitch.on
            {
                if NSUserDefaults.standardUserDefaults().objectForKey("syncChoice") != nil
                {
                    print("setting Camera Roll AutoSync -> On")
                    print(NSUserDefaults.standardUserDefaults().objectForKey("syncChoice"))
                    preferences.cameraAutosync = true
        
                    NSUserDefaults.standardUserDefaults().setInteger(1, forKey: "syncSwitchStatus")
                    self.performSegueWithIdentifier("syncSwitchOn", sender: self)
                }
                else{
                    self.autosyncSwitch.on = false
                    let alertVC = UIAlertController(
                        title: "Message",
                        message: "Please select Copy/Move",
                        preferredStyle: .Alert
                    )
                    let okAction = UIAlertAction(
                        title: "OK",
                        style: .Default,
                        handler: nil
                    )
                    alertVC.addAction(okAction)
                    presentViewController(alertVC, animated: true, completion: nil)
                }
            }
            else
            {
                print("setting Camera Roll AutoSync -> Off")
                NSUserDefaults.standardUserDefaults().setInteger(0, forKey: "syncSwitchStatus")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("syncChoice")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("selectedAlbums")
                preferences.cameraAutosync = false
            }
        appCoreData.saveContext()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        if ((NSUserDefaults.standardUserDefaults().objectForKey("syncSwitchStatus")?.integerValue) != nil)
        {
            if ((NSUserDefaults.standardUserDefaults().objectForKey("syncSwitchStatus")?.integerValue) == 1)
            {
                self.autosyncSwitch.on = true
            }
            else{
                self.autosyncSwitch.on = false
            }
        }
        else{
            self.autosyncSwitch.on = false
        }
        self.selectedIndex = Int(self.preferences.autosyncModeValue)
        //self.autosyncSwitch.on = self.preferences.cameraAutosync
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let section = indexPath.section
        let rows = self.tableView.numberOfRowsInSection(section)
        selectedIndex = indexPath.row
        if section != 0
        {
            for row in 0..<rows
            {
                if let cell =   self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: section))
                {
                    if row == selectedIndex
                    {
                        cell.accessoryType = .Checkmark
                        preferences.autosyncModeValue = Int32(row)
                        NSUserDefaults.standardUserDefaults().setInteger(row, forKey: "syncChoice")
                        appCoreData.saveContext()
                    }
                    else
                    {
                        cell.accessoryType = .None
                    }
                }
            }
        }
        
        print("user selected row -> \(selectedIndex)")
        self.tableView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        switch segue.identifier!
        {
        case "syncSwitchOn":
            segue.destinationViewController as? CameraSyncSelectFolderViewController
            
        default:
            NSLog("No identifier found!")
            break
        }
    }

    
}
