//
//  DefaultSortSettingController.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-11-24.
//  Copyright © 2015 iXTRA Technologies. All rights reserved.
//

import UIKit

class DefaultSortSettingController: UITableViewController {
    
    var options = ["Alphabetical", "Recent", "Starred Alphabetical", "Starred Recent"]
    var selectedIndex: Int!
    var preferences: Preferences!
    let appCoreData = AppCoreData()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let label = "Default Sort"
        self.navigationItem.title = label.uppercaseString
        
        self.selectedIndex = Int(self.preferences.defaultSortValue)
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
            self.preferences.defaultSortValue = Int32(selectedIndex)
            self.preferences.isDefaultSortSet = true
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
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath)
    {
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
