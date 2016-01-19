//
//  SystemPreferencesController.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-10-13.
//  Copyright © 2015 iXTRA Technologies. All rights reserved.
//

import UIKit

class SystemPreferencesController: UITableViewController
{
    // MARK: Properties
    let appCoreData = AppCoreData()
    var preferences: Preferences!
    
    @IBOutlet weak var chargeOnlySwitch: UISwitch!
    @IBOutlet weak var persistentFilterSwitch: UISwitch!
    @IBOutlet weak var defaultViewDetail: UILabel!
    @IBOutlet weak var defaultSortDetail: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let label = "Setting"
        self.navigationItem.title = label.uppercaseString
        
        // hide back button
        self.navigationItem.setHidesBackButton(true, animated: false)
        // setup Done button on right side
        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "segueBack")
        barButtonItem.tintColor = UIColor(red: 74/255, green: 146/255, blue: 226/255, alpha: 1.0)
        self.navigationItem.setRightBarButtonItem(barButtonItem, animated: true)
        
        // get preferences
        self.getPreferences()
    }

    func getPreferences()
    {
        self.preferences = self.appCoreData.fetchPreferences()
        self.persistentFilterSwitch.on = self.preferences.persistentFilter
        self.chargeOnlySwitch.on = self.preferences.chargeOnly
        self.defaultViewDetail.text = self.preferences.getDefaultView
        self.defaultSortDetail.text = self.preferences.getDefaultSortName
    }
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.getPreferences()
    }
    
    func segueBack()
    {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction func setPersistentFilter(sender: AnyObject)
    {
        if self.persistentFilterSwitch.on
        {
            print("setting Persistent Filter On")
            // write preferences to file
            preferences.persistentFilter = true
        }
        else
        {
            print("setting Persistent Filter Off")
            // write preferences to file
            preferences.persistentFilter = false
        }
        
        appCoreData.saveContext()
    }
    
    @IBAction func setChargeOnly(sender: AnyObject)
    {
        if self.chargeOnlySwitch.on
        {
            print("setting Charge Only -> On")
            preferences.chargeOnly = true
        }
        else
        {
            print("setting Charge Only -> Off")
            preferences.chargeOnly = false
        }
        appCoreData.saveContext()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        switch segue.identifier!
        {
        case "SelectDefaultView":
            if let defaultView = segue.destinationViewController as? DefaultViewSettingController
            {
                defaultView.preferences = self.preferences
                //  selectedIndex must come from preference setting 0 << 5
            }
        case "SelectDefaultSort" :
            if let defaultSortView = segue.destinationViewController as? DefaultSortSettingController
            {
                defaultSortView.preferences = self.preferences
                //  selectedIndex must come from preference setting 0 << 3
            }
        case "SelectCameraRollSync":
            if let cameraRollSyncView = segue.destinationViewController as? CameraRollSyncSettingController
            {
                cameraRollSyncView.preferences = self.preferences
                // selectedIndex must come from preference setting 0 << 1
            }
        case "ShowAbout":
            segue.destinationViewController as! AboutViewController
            
        case "ShowPasswordScreen":
            segue.destinationViewController as! AppPassCodeViewController
            
        default:
            print("segue not identified with -> \(segue.identifier!)")
        }
    }
}
