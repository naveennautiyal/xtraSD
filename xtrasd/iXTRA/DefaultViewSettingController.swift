//
//  DefaultViewSettingController.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-11-24.
//  Copyright © 2015 iXTRA Technologies. All rights reserved.
//

import UIKit
import CoreData

class DefaultViewSettingController: UITableViewController {

    var options = ["All Files", "All Media", "Documents", "Audio", "Video", "Photo"]
    var selectedIndex: Int!
    var preferences: Preferences!
    let appCoreData = AppCoreData()
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let label = "Default View"
        self.navigationItem.title = label.uppercaseString
        self.selectedIndex = Int(self.preferences.defaultViewValue)
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // #warning Incomplete implementation, return the number of rows
        return options.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("optionCell", forIndexPath: indexPath)
        
        cell.textLabel?.text = options[indexPath.row]
        
        if indexPath.row == selectedIndex
        {
            cell.accessoryType = .Checkmark
            self.preferences.defaultViewValue = Int32(selectedIndex)
            appCoreData.saveContext()
        }
        else
        {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        selectedIndex = indexPath.row
        let selectedFiler = options[selectedIndex]
                
        switch selectedFiler
        {
            case "All Files":
            self.preferences.persistentFilterMode = .AllFiles
            case "All Media":
            self.preferences.persistentFilterMode = .AllMedia
            case "Documents":
            self.preferences.persistentFilterMode = .Document
            case "Audio":
            self.preferences.persistentFilterMode = .Audio
            case "Video":
            self.preferences.persistentFilterMode = .Video
            case "Photo":
            self.preferences.persistentFilterMode = .Photo
            default:
            self.preferences.persistentFilterMode = .AllFiles
        }
        
        self.preferences.defaultViewValue = Int32(selectedIndex)
        
        self.saveContext()
        
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath)
    {
    }
    
    func saveContext()
    {
        // save context data into perisentent store
        do
        {
            try context.save()
            print("Saved context")
        }
        catch
        {
            print("Could not save \(error)")
        }
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
