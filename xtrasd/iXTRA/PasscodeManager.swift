//
//  PasscodeManager.swift
//  xtraSD
//
//  Created by optimusmac-12 on 04/01/16.
//  Copyright © 2016 iXTRA Technologies. All rights reserved.
//

import UIKit

class PasscodeManager: UIViewController {

    @IBOutlet weak var labelMsg: UILabel!
    @IBOutlet weak var dot1: UIImageView!
    @IBOutlet weak var dot2: UIImageView!
    @IBOutlet weak var dot3: UIImageView!
    @IBOutlet weak var dot4: UIImageView!
    var passcode: String = ""
    var passcodeTemp: String = ""
    var count: Int = 0
    var savedPasscode: String = ""
    var mode = String()
    var counter: Int = 0
    var window: UIWindow?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        self.navigationItem.title = "Enter Passcode"
        
        //added a cancel button to allow user to cancel in between Passcode setup/disbale/change mode
        let cancelButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelPressed")
        cancelButtonItem.tintColor = UIColor(red: 74/255, green: 146/255, blue: 226/255, alpha: 1.0)
        self.navigationItem.setRightBarButtonItem(cancelButtonItem, animated: true)
        
        
                if NSUserDefaults.standardUserDefaults().valueForKey("passcode") != nil
        {
            savedPasscode = NSUserDefaults.standardUserDefaults().valueForKey("passcode") as! String
            
        }
        if mode == "setPasscode"
        {
            labelMsg.text = "Please provide a passcode"
            counter = 2
        }
        else if mode == "changePasscode"
        {
            labelMsg.text = "Please enter your old passcode"
            counter = 3
        }
        else if mode == "" || mode == "disablePasscode"
        {
            labelMsg.text = "Please enter you passcode"
            counter = 0
        }
        
        setEmptyDots()


        // Do any additional setup after loading the view.
    }

    func setEmptyDots()     // To clear all dots to empty state
    {
        dot1.image = UIImage(named: "empty_circle")
        dot2.image = UIImage(named: "empty_circle")
        dot3.image = UIImage(named: "empty_circle")
        dot4.image = UIImage(named: "empty_circle")
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onePressed(sender: AnyObject) {
        print("one")
        passcode = passcode + "1"     // Appending the number to create a Passcode String
        count++                         // Used to count number of digits
        fillDot()                       // will change corresponding dot's state from empty to filled
        if count == 4{
            checkPasscode()             // if 4 digits are received then proceed
        }
    }
    @IBAction func twoPressed(sender: AnyObject) {
        print("two")
        passcode = passcode + "2"
        count++
        fillDot()
        if count == 4{
            checkPasscode()
        }
    }
    @IBAction func threePressed(sender: AnyObject) {
        print("three")
        passcode = passcode + "3"
        count++
        fillDot()
        if count == 4{
            checkPasscode()
        }

    }
    @IBAction func fourPressed(sender: AnyObject) {
        print("four")
        passcode = passcode + "4"
        count++
        fillDot()
        if count == 4{
            checkPasscode()
        }
    }
    @IBAction func fivePressed(sender: AnyObject) {
        print("five")
        passcode = passcode + "5"
        count++
        fillDot()
        if count == 4{
            checkPasscode()
        }
    }
    @IBAction func sixPressed(sender: AnyObject) {
        print("six")
        passcode = passcode + "6"
        count++
        fillDot()
        if count == 4{
            checkPasscode()
        }

    }
    @IBAction func sevenPressed(sender: AnyObject) {
        print("seven")
        passcode = passcode + "7"
        count++
        fillDot()
        if count == 4{
            checkPasscode()
        }

    }
    @IBAction func eightPressed(sender: AnyObject) {
        print("eight")
        passcode = passcode + "8"
        count++
        fillDot()
        if count == 4{
            checkPasscode()
        }

    }
    @IBAction func ninePressed(sender: AnyObject) {
        print("nine")
        passcode = passcode + "9"
        count++
        fillDot()
        if count == 4{
            checkPasscode()
        }

    }
    @IBAction func zeroPressed(sender: AnyObject) {
        print("zero")
        passcode = passcode + "0"
        count++
        fillDot()
        if count == 4{
            checkPasscode()
        }
        
    }
    @IBAction func deletePressed(sender: AnyObject) {
        print("delete")
        passcode = String(passcode.characters.dropLast())   // Removing last digit from passcode string
        if count > 0
        {
            emptyDot()
            count--                     // reduce digits count as delete button has been pressed
        }
//        else
//        {
//            self.navigationController?.popViewControllerAnimated(true)
//        }
    }
        
    func checkPasscode()
    {
        if counter == 3     // when change passcode request is made
        {
            if passcode == savedPasscode{
                counter--
                labelMsg.text = "Please enter a new passcode"
            }
            else
            {
                showAlert("You entered wrong Passcode.Please enter correct Passcode",popBack: false)
            }
            
        }
        else if counter == 2    // when create new passcode request is made
        {
            passcodeTemp = passcode
            counter--
            labelMsg.text = "Please re-enter your passcode"
        }
        else if counter == 1    // check if user has entered same passcode twice
        {
            if passcode == passcodeTemp{
                savedPasscode = passcode
                
                if mode == "setPasscode" || mode == "changePasscode"
                {
                    //performSegueWithIdentifier("passCodeSet", sender: self)
                    NSUserDefaults.standardUserDefaults().setValue("on", forKey: "passcodeProtection")
                    NSUserDefaults.standardUserDefaults().setValue(savedPasscode, forKey: "passcode")
                     counter--
                    
                    if mode == "setPasscode"{
                        showAlert("Your passcode seting has been updated successfully",popBack: true)
                    }
                    else if mode == "changePasscode"{
                        showAlert("Your passcode has been changed successfully",popBack: true)
                    }
                }
            }
            else{
                showAlert("You entered a wrong passcode. Please re-enter",popBack: false)
            }
        }
        else
        {
            if passcode == savedPasscode{
                if mode == ""{
                 
                // reinitialising initial view controller to RootViewController after user is found authentic
                let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let viewController = mainStoryboard.instantiateViewControllerWithIdentifier("LaunchScreen")
                UIApplication.sharedApplication().keyWindow?.rootViewController = viewController;
                    
                }
                else if mode == "disablePasscode"{
                    showAlert("Passcode has been disabled",popBack: true)
                    // changing status of passcodeProtection and erasing passcode after disable of passcode is done
                    NSUserDefaults.standardUserDefaults().setValue("off", forKey: "passcodeProtection")
                    NSUserDefaults.standardUserDefaults().removeObjectForKey("passcode")
                }
            }
            else
            {
                showAlert("You entered a wrong passcode. Please re-enter",popBack: false)
            }
        }
        count = 0
        passcode = ""
        UIView.animateWithDuration(0, animations: {() in} , completion: {(Bool) in
            self.setEmptyDots()
        });
    }
    
    func showAlert(message: String, popBack: Bool){
        
        let alertVC = UIAlertController(
            title: "Message",
            message: message,
            preferredStyle: .Alert
        )
        let okAction = UIAlertAction(
            title: "OK",
            style: .Default,
            handler: { action in
                if popBack == true
                {
                self.navigationController?.popViewControllerAnimated(true)
            }
            }
        )
        alertVC.addAction(okAction)
        presentViewController(alertVC, animated: true, completion: nil)
    }
    
    func fillDot()              // for filling dots one by one as digits are pressed
    {
        switch count
        {
        case 1: dot1.image = UIImage(named: "filled_circle")
        break;

        case 2: dot2.image = UIImage(named: "filled_circle")
        break;
            
        case 3: dot3.image = UIImage(named: "filled_circle")
        break;
            
        case 4: dot4.image = UIImage(named: "filled_circle")
        break;
            
        default: break
        }
    }
    func emptyDot()         // for emptying dots one by one as cancel is pressed
    {
        switch count
        {
        case 1: dot1.image = UIImage(named: "empty_circle")
        break;
            
        case 2: dot2.image = UIImage(named: "empty_circle")
        break;
            
        case 3: dot3.image = UIImage(named: "empty_circle")
        break;
            
        case 4: dot4.image = UIImage(named: "empty_circle")
        break;
            
        default: break
        }
    }
    
    func cancelPressed(){
        self.navigationController?.popViewControllerAnimated(true)
    }
}
