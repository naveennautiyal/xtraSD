//
//  AccessoryDetailViewController.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-08-25.
//  Copyright (c) 2015 iXTRA Technologies. All rights reserved.
//

import Foundation
import UIKit
import XTR100



// Controller to display details of attached external accessory
class AccessoryDetailViewController: UITableViewController
{
    
    //MARK: Properties
    @IBOutlet weak var accessoryName: UILabel!
    @IBOutlet weak var manufacturerLabel: UILabel!
    @IBOutlet weak var modelSerialNumberLabel: UILabel!
    @IBOutlet weak var modelNumberLabel: UILabel!
    @IBOutlet weak var firmwareLabel: UILabel!
    @IBOutlet weak var hardwareLabel: UILabel!

    
    // MARK: View functions
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool)
    {
        navigationItem.title = "Accessory"
        self.navigationItem.setRightBarButtonItem(UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "checkConnection"), animated: true)
    }
    
    func refresh()
    {
        self.viewDidLoad()
    }
    
    // MARK: accessory information
    func updateAccessoryInformation()
    {
        // display accessory information
        do
        {
            self.accessoryName.text          = try device.getModelName()
        }
        catch let error as NSError
        {
            NSLog("error -> %@", error)
            self.accessoryName.text = "No Accessory Found"
        }
        
        do
        {
            self.modelSerialNumberLabel.text = try device.getSerialNumber()
        }
        catch let error as NSError
        {
            NSLog("error -> %@", error)
            self.modelSerialNumberLabel.text = ""
        }
        
        do
        {
            self.manufacturerLabel.text      = try device.getManufacturerLabel()
        }
        catch let error as NSError
        {
            NSLog("error -> %@", error)
            self.manufacturerLabel.text = ""
        }
        
        do
        {
            self.modelNumberLabel.text       = try device.getModelNumber()
        }
        catch let error as NSError
        {
            NSLog("error -> %@", error)
            self.modelNumberLabel.text = ""
        }
        
        do
        {
            self.firmwareLabel.text          = try device.getFirmwareRevision()
        }
        catch let error as NSError
        {
            NSLog("error -> %@", error)
            self.firmwareLabel.text = ""
        }
        
        do
        {
            self.hardwareLabel.text          = try device.getHardwareRevision()
        }
        catch let error as NSError
        {
            NSLog("error -> %@", error)
            self.hardwareLabel.text = ""
        }
    }
    
    // MARK: app update on accessory connection
    func checkConnection()
    {
        if device.isConnected()
        {
            accessoryIsConnected = true
        }
        else
        {
            accessoryIsConnected = false
        }
        self.updateAccessoryInformation()
    }
    
}
