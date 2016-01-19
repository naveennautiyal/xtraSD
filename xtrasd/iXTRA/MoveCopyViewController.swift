//
//  MoveCopyViewController.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-11-18.
//  Copyright © 2015 iXTRA Technologies. All rights reserved.
//

import UIKit
import CoreData

class MoveCopyViewController: UICollectionViewController
{
    //MARK: Properties
    enum desiredAction
    {
        case Move, Copy
    }
    
    let folderCellIdentifier = "folderCell"
    
    var currentDirUrl: NSURL!
    var rootUrl: NSURL!
    var label: String!
    
    let fileManager = NSFileManager.defaultManager()
    var parent: Directory!
    var dirArray: [Directory] = []
    var selectedItemsy: [AnyObject] = []
    var selectedIndeces: [Int] = []
    var calledAction: desiredAction!
    let appCoreData = AppCoreData()
    
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    // MARK: Buttons

    
    
    @IBAction func moveItemsButton(sender: AnyObject)
    {
        print("moveItemsButton pressed ... items will be moved to -> \(currentDirUrl)")
        let dirsToMove = appCoreData.fetchSelectedObjects(objects: .Directory)
        let filesToMove = appCoreData.fetchSelectedObjects(objects: .File)
        print("will move this many dirs -> \(dirsToMove.count) and files -> \(filesToMove.count)")
        let newParent = appCoreData.fetchParentObjectAtURL(currentDirUrl)
        for dir in dirsToMove
        {
            let child = dir as! Directory
            
            do
            {
                let toURL = newParent.url?.URLByAppendingPathComponent(child.name!, isDirectory: true)
                print("copy file -> \(child.url!) to -> \(toURL)")
                try fileManager.moveItemAtURL(child.url!, toURL: toURL!)
                appCoreData.moveChildDir(child, newParent: newParent)
            }
            catch let error as NSError
            {
                print("MoveCopyViewController: Error in file copy -> \(error)")
            }
        }
        
        for file in filesToMove
        {
            let child = file as! File
            
            do
            {
                let toURL = newParent.url?.URLByAppendingPathComponent(child.name!, isDirectory: false)
                print("copy file -> \(child.url!) to -> \(toURL)")
                try fileManager.moveItemAtURL(child.url!, toURL: toURL!)
                appCoreData.moveChildFile(child, newParent: newParent)
                // TODO: tie into device.copyItemAtURL
            }
            catch let error as NSError
            {
                print("MoveCopyViewController: Error in file copy -> \(error)")
            }
        }
        
        self.performSegueWithIdentifier("unwindToRoot", sender: self)

    }
    @IBAction func copyItemsButton(sender: AnyObject)
    {
        print("copyItemsButton pressed ... items will be copied to -> \(currentDirUrl)")
        let dirsToCopy = appCoreData.fetchSelectedObjects(objects: .Directory)
        let filesToCopy = appCoreData.fetchSelectedObjects(objects: .File)
        print("will copy this many dirs -> \(dirsToCopy.count) and files -> \(filesToCopy.count)")
        let newParent = appCoreData.fetchParentObjectAtURL(currentDirUrl)
        for dir in dirsToCopy
        {
            let child = dir as! Directory
            
            do
            {
                let toURL = newParent.url?.URLByAppendingPathComponent(child.name!, isDirectory: true)
                print("copy file -> \(child.url!) to -> \(toURL)")
                try fileManager.copyItemAtURL(child.url!, toURL: toURL!)
                appCoreData.copyChildDir(child, newParent: newParent)
            }
            catch let error as NSError
            {
                print("MoveCopyViewController: Error in file copy -> \(error)")
            }

        }
        
        for file in filesToCopy
        {
            let child = file as! File
            
            
            do
            {
                let toURL = newParent.url?.URLByAppendingPathComponent(child.name!, isDirectory: false)
                print("copy file -> \(child.url!) to -> \(toURL)")
                try fileManager.copyItemAtURL(child.url!, toURL: toURL!)
                appCoreData.copyChildFile(child, newParent: newParent)
                // TODO: tie into device.copyItemAtURL
            }
            catch let error as NSError
            {
                print("MoveCopyViewController: Error in file copy -> \(error)")
            }
        }
        self.performSegueWithIdentifier("unwindToRoot", sender: self)
    }

    @IBAction func AddFolder(sender: AnyObject)
    {
        print("Add Folder to the following url -> \(currentDirUrl)")
        
        self.getName() { result in
            print("alert result -> \(result)")
            
            let newDirUrl = self.currentDirUrl?.URLByAppendingPathComponent(result, isDirectory: true)
            
            do
            {
                try NSFileManager.defaultManager().createDirectoryAtURL(newDirUrl!, withIntermediateDirectories: true, attributes: nil)
                
                // add new directory to core data
                self.appCoreData.addChildDir(self.parent, url: newDirUrl!)
                self.appCoreData.saveContext()
                self.dirArray.append(self.appCoreData.fetchObjectAtUrl(newDirUrl!) as! Directory)
                self.collectionView!.reloadData()
                
                print("dirArray is now -> \(self.dirArray.count)")
            }
            catch let error as NSError
            {
                print("Cannot create directory -> error: \(error)")
            }
            catch
            {
                fatalError()
            }
            
            self.dismissViewControllerAnimated(true, completion: { () -> Void in
                
            })
            
        }
        self.refresh()
    }

    
    // MARK: views
    // Refresh collectionView
    func refresh()
    {
        self.fetchDirectoriesOfCurrentDir(currentDirUrl)
        self.collectionView!.reloadData()
    }
    
   override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // hide back button
        self.navigationItem.setHidesBackButton(true, animated: false)
        
        print("calledAction -> \(calledAction)")
        // setup root url path
        do
        {
            rootUrl = try fileManager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
            // TODO: set rootURL to FileAccess.getCurrentDirectory
            // rootURL = device.getCurrentDirectory()
        }
        catch let error as NSError
        {
            print("Error in fileManager read at directory ->\(error)")
            rootUrl = nil
        }
        
        // assign root dir to temporary placeholder
        if currentDirUrl == nil
        {
            currentDirUrl = rootUrl
        }

        // get directories of current directory
        self.fetchDirectoriesOfCurrentDir(currentDirUrl)
        self.collectionView!.reloadData()
        // figure out which ones are selected by getting a list of indeces
        
        label = ( currentDirUrl != rootUrl ) ? currentDirUrl?.lastPathComponent : "HOME"
        
        self.navigationItem.title = label?.uppercaseString
        self.navigationController?.toolbarHidden  = false
        self.navigationController?.toolbar.backgroundColor = UIColor.whiteColor()
        self.navigationController?.toolbar.barTintColor = UIColor.whiteColor()
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return (dirArray.count > 0) ? dirArray.count : 1
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(folderCellIdentifier, forIndexPath: indexPath) as! FolderCollectionViewCell
        if dirArray.count > 0
        {
            let data =  dirArray[indexPath.row]
            let folderName = data.url!.lastPathComponent
            let folderImage = UIImage(named: "folder")
            let selectedFolderImage = UIImage(named: "selectedFolder")
            cell.icon.image = data.isSelected ? selectedFolderImage : folderImage
            cell.folderName.text = folderName
        }
        else
        {
            
            let label = UILabel(frame: CGRectMake(0,0,self.view.bounds.size.width, 30))
            label.text = "No Folders Found"
            label.center = CGPointMake(self.view.bounds.size.width/2, 15.0)
            label.textAlignment = .Center
            self.collectionView!.addSubview(label)
        }
        
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        
        if dirArray.count > 0
        {
            let selectedUrl = dirArray[indexPath.row].url!
            let sceneIdentifier = calledAction == .Move ? "MoveView" : "CopyView"
            print("didSelect sceneIdentifier -> \(sceneIdentifier)")
            let childView = self.storyboard?.instantiateViewControllerWithIdentifier(sceneIdentifier) as! MoveCopyViewController
            childView.currentDirUrl = selectedUrl
            childView.calledAction = calledAction == .Move ? .Move : .Copy
            childView.title = selectedUrl.lastPathComponent
            childView.navigationItem.setLeftBarButtonItem(nil, animated: true)
            self.navigationController?.pushViewController(childView, animated: true)
        }

    }
    
    // MARK: Utility functions
    // function to create an alert to get folder name
    func getName(callback: (String) -> ())
    {
        
        // alert user and ask for file name
        let alert = UIAlertController(title:"", message: "", preferredStyle: .Alert)
        alert.title = "New Folder Name"
        alert.message = "Please enter new folder name"
        
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction) -> Void in
            callback("")
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            // get textField results and assign it to inputString
            let textField = alert.textFields![0]
            callback(textField.text!)
        }))
        
        alert.addTextFieldWithConfigurationHandler({ textField -> Void in
            textField.placeholder = "New name"
        })
        
        self.presentViewController(alert, animated:true, completion: nil)
    }
    
    func fetchDirectoriesOfCurrentDir(url: NSURL)
    {

        // initiate link to core data Directory table
        let dirEntity = NSEntityDescription.entityForName("Directory", inManagedObjectContext: context)
        let request = NSFetchRequest()
        request.entity = dirEntity
        // specify how we want the results to be sorted
        let sort = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [sort]
        
        // search specifically for
        let pred = NSPredicate(format: "(url = %@)", url)
        request.predicate = pred
        
        var results: [Directory] = []
        
        do {
            results = try context.executeFetchRequest(request) as! [Directory]
            print("results.count -> \(results.count)")
            
            if results.count > 1
            {
                NSLog("Houston we have found duplicate urls in the Directory table!!!! \n Please check your code!")
            }
            else
            {
                // whew! we have only one unique url :)
                parent = results[0]
                // from CoreData get array of directories belonging to rootUrl
                
                self.dirArray = parent.hasDirectories?.sortedArrayUsingDescriptors([sort]) as! [Directory]
                // from CoreData get array of files belonging to rootUrl

                print("result ->\(parent.name)")
                print("dirArray.count -> \(dirArray.count)")

            }
            
        } catch {
            print("error in fetch \(error)")
        }
        
    }



}
