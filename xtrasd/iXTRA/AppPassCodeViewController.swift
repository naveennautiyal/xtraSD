//
//  AppPassCodeViewController.swift
//  xtraSD
//
//  Created by optimusmac-12 on 04/01/16.
//  Copyright © 2016 iXTRA Technologies. All rights reserved.
//

import UIKit

class AppPassCodeViewController: UITableViewController {

    @IBOutlet weak var enableSwitch: UISwitch!
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        if NSUserDefaults.standardUserDefaults().valueForKey("passcodeProtection") != nil
//        {
//            
//            if NSUserDefaults.standardUserDefaults().objectForKey("passcodeProtection") as! String == "on"
//            {
//                enableSwitch.on = true
//            }
//        }
//        else
//        {
//            enableSwitch.on = false
//        }
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        if NSUserDefaults.standardUserDefaults().valueForKey("passcodeProtection") != nil
        {
            
            if NSUserDefaults.standardUserDefaults().objectForKey("passcodeProtection") as! String == "on"
            {
                enableSwitch.on = true
            }
            else if NSUserDefaults.standardUserDefaults().objectForKey("passcode") == nil
            {
                enableSwitch.on = false
            }
        }
        else
        {
            enableSwitch.on = false
        }
    }
    @IBAction func enableSwitchChange(sender: AnyObject) {
        
        if self.enableSwitch.on
        {
//        NSUserDefaults.standardUserDefaults().setValue("on", forKey: "passcodeProtection")
            self.performSegueWithIdentifier("setPasscode", sender: self)
        }
        else{
            self.performSegueWithIdentifier("disablePasscode", sender: self)
//        NSUserDefaults.standardUserDefaults().setValue("off", forKey: "passcodeProtection")
//        NSUserDefaults.standardUserDefaults().removeObjectForKey("passcode")
        }
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        switch segue.identifier!
        {
        case "setPasscode":
            let dest = segue.destinationViewController as! PasscodeManager
            dest.mode = "setPasscode"
            break;
        
        case "disablePasscode":
            let dest = segue.destinationViewController as! PasscodeManager
            dest.mode = "disablePasscode"
            break;
            
        case "changePasscode":
            if self.enableSwitch.on
            {
                let dest = segue.destinationViewController as! PasscodeManager
                dest.mode = "changePasscode"
            }
            else
            {
                let alertVC = UIAlertController(
                    title: "Message",
                    message: "Please enable and set a passcode first",
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
            
        default:
            NSLog("No identifier found!")
            break
        }
    }
}

