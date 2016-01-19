//
//  SearchViewController.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-11-24.
//  Copyright © 2015 iXTRA Technologies. All rights reserved.
//

import UIKit
import CoreData


class FileObject
{
    var name: String!
    var url: NSURL!
}

class SearchViewController: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating
{
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    var searchController: UISearchController!
    let searchRequest = NSFetchRequest()
    
    var filteredData: [AnyObject] = []
    
    let appCoreDate = AppCoreData()
    let lib = Library()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        // setup search
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.searchBar.delegate = self
        self.searchController.searchBar.sizeToFit()
        // add search bar view
        //self.tableView.tableHeaderView = self.searchController.searchBar
        self.view.addSubview(self.searchController.searchBar);
        self.definesPresentationContext = true
        
        // setup navigation bar
        let label = "Search"
        self.navigationItem.title = label.uppercaseString
        // hide back button
        self.navigationItem.setHidesBackButton(true, animated: false)
        // setup Done button on right side
        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "segueBack")
        barButtonItem.tintColor = UIColor(red: 74/255, green: 146/255, blue: 226/255, alpha: 1.0)
        self.navigationItem.setRightBarButtonItem(barButtonItem, animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true);
        
        let h =  self.tableView.frame.size.width;
        let w =  self.tableView.frame.size.height;
        
        self.tableView.frame = CGRect(x: 0, y: 100, width: w, height:h-100);
    }

    func segueBack()
    {
        //self.navigationController?.popToRootViewControllerAnimated(true)
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - Table view data source
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // #warning Incomplete implementation, return the number of rows
        return filteredData.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("resultCell")! as UITableViewCell
        let data = filteredData[indexPath.row]
        cell.textLabel!.text = data.name
        
        if lib.isUrlDirectory(data.url()) == "YES"
        {
            cell.imageView!.image = UIImage(named: "folder")
        }
        else
        {
            cell.imageView!.image = lib.getMimeTypeImageForURL(data.url())
        }
        
        return cell
    }
    // MARK: search functions
    func updateSearchResultsForSearchController(searchController: UISearchController)
    {
        
        let searchString = searchController.searchBar.text
        if searchString != nil
        {
            self.searchForText(searchString!)
            self.tableView.reloadData()
        }
        
    }
    
    func searchForText(searchString:String)
    {
        let predicateFormat = "%K CONTAINS[cd] %@"
        let searchAttribute = "name"
        
        let predicate = NSPredicate(format: predicateFormat, searchAttribute, searchString)
        self.searchRequest.predicate = predicate
        
        let dirEntity = NSEntityDescription.entityForName("Directory", inManagedObjectContext: context)
        self.searchRequest.entity = dirEntity
        

        do
        {
            self.filteredData = try context.executeFetchRequest(searchRequest)
        }
        catch let error as NSError
        {
            NSLog("searchFetchRequest in Directory failed -> %@", error)
        }
        
        let fileEntity = NSEntityDescription.entityForName("File", inManagedObjectContext: context)
        self.searchRequest.entity = fileEntity
        
        do
        {
            let results = try context.executeFetchRequest(searchRequest)
            self.filteredData.appendContentsOf(results)
        }
        catch let error as NSError
        {
            NSLog("searchFetchRequest in File failed -> %@", error)
        }
    }

}
