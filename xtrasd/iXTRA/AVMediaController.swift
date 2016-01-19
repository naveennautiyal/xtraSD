//
//  AVMediaController.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-11-05.
//  Copyright © 2015 iXTRA Technologies. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class AVMediaController: AVPlayerViewController
{
    // MARK: properties
    var fileArray: [File]!
    var index: Int = 0
    var fileUrl: NSURL!
    let fileManager = NSFileManager.defaultManager()
    let appCoreData = AppCoreData()
    
    @IBOutlet var menu: UIView!

    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // hide back button
        self.navigationItem.setHidesBackButton(true, animated: false)
        // setup Done button on right side
        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "segueBack")
        barButtonItem.tintColor = UIColor(red: 74/255, green: 146/255, blue: 226/255, alpha: 1.0)
        
        // setup Done button, menu button on left side
        self.navigationItem.setLeftBarButtonItem(barButtonItem, animated: true)
        
        // Added menu button to show all file operations like copy,move,search,rename,delete,star,cancel
        let menuButton = UIBarButtonItem(image: UIImage(named:"more"), style: .Plain, target: self, action: "showMenu:")
        
        //Added share button to share current object
        let shareButton = UIBarButtonItem(image: UIImage(named:"share"), style: .Plain, target: self, action: "shareItem")
        self.navigationItem.rightBarButtonItems = [menuButton, shareButton]
        
        fileUrl = fileArray[index].url
        self.addGestures()
        self.fetch(fileUrl)
    }
    
    
    @IBAction func showMenu(sender: AnyObject)
    {
        menu.backgroundColor = UIColor .blackColor().colorWithAlphaComponent(0.8)
        menu.frame = CGRectMake(0,0, self.view.bounds.size.width, self.view.bounds.size.height)
        self.view.addSubview(menu)
    }
    
    @IBAction func copyButton(sender: AnyObject) {
        self.markItemSelected(fileArray[self.index])
        performSegueWithIdentifier("DisplayCopyDestination", sender: self)
    }
    
    @IBAction func moveButton(sender: AnyObject) {
        self.markItemSelected(fileArray[self.index])
        performSegueWithIdentifier("DisplayMoveDestination", sender: self)
    }
    
    @IBAction func searchButton(sender: AnyObject) {
        performSegueWithIdentifier("DisplaySearchView", sender: self)
    }
    
    @IBAction func deleteButton(sender: AnyObject) {
        
        let filesToBeDeleted = fileArray as [File]!
        let file = filesToBeDeleted[self.index]
        
        do
        {
            try fileManager.removeItemAtURL(file.url!)
            appCoreData.deleteChildFile(file )
            self.navigationController?.popViewControllerAnimated(true)
        }
        catch let error as NSError
        {
            NSLog("Error in deleting directory object -> %@", error)
        }
    }
    
    @IBAction func starButton(sender: AnyObject) {
        
        let files = fileArray as [File]
        files[self.index].isStarred = true
        
        appCoreData.saveContext()
        let alertVC = UIAlertController(
            title: "Message",
            message: "This file has been Starred",
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
    
    @IBAction func renameButton(sender: AnyObject) {
        self.markItemSelected(fileArray[self.index])
        let selectedObjects = fileArray as NSArray!
        // ask user for new name
        print("ok user understands ...")
        self.getName(selectedObjects![self.index].name , type: .Rename) { newName in
            if !newName.isEmpty
            {
                
                var url: NSURL!
                // figure out what kind of file object we have
                let dirs = self.appCoreData.fetchSelectedObjects(objects: .Directory) as! [Directory]
                let files = self.fileArray as [File]!
                if dirs.count > 0
                {
                    print("we're dealing with a directory")
                    url = dirs[self.index].url
                    let newUrl = url.URLByDeletingLastPathComponent?.URLByAppendingPathComponent(newName)
                    do
                    {
                        try self.fileManager.moveItemAtURL(url, toURL: newUrl!)
                        // rename appropriate object
                        self.appCoreData.renameChildDir(dirs[self.index], newName: newName)
                    }
                    catch let error as NSError
                    {
                        NSLog("Error in renaming directory -> \(error)")
                    }
                    
                }
                
                if files.count > 0
                {
                    print("we're dealing with a file")
                    url = files[self.index].url
                    let newUrl = url.URLByDeletingLastPathComponent?.URLByAppendingPathComponent(newName)
                    do
                    {
                        try self.fileManager.moveItemAtURL(url, toURL: newUrl!)
                        // rename appropriate object
                        self.appCoreData.renameChildFile(files[self.index], newName: newName)
                    }
                    catch let error as NSError
                    {
                        NSLog("Error in renaming file -> \(error)")
                    }
                }
            }
        }
    }
    enum itemToBeRenamed
    {
        case Folder, File, Rename
    }
    
    func getName(currentName: String, type: itemToBeRenamed, callback: (String) -> ())
    {
        
        // alert user and ask for file name
        let alert = UIAlertController(title:"", message: "", preferredStyle: .Alert)
        switch type {
        case .File:
            alert.title = "New File Name"
            alert.message = "Please enter new file name"
        case .Folder:
            alert.title = "New Folder Name"
            alert.message = "Please enter new folder name"
        case .Rename:
            alert.title = "Name Change"
            alert.message = "Please enter new name"
        }
        
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
            switch type
            {
            case .Rename: textField.text = currentName
            default: textField.placeholder = "New Name"
            }
        })
        
        self.presentViewController(alert, animated:true, completion: nil)
        
        
    }
    
    @IBAction func cancelButton(sender: AnyObject) {
        menu.removeFromSuperview()
    }
    
    func markItemSelected(file:File)
    {
        // Add select tag to current file
        appCoreData.setSelectTagForChildFile(file)
    }
    
    // shareItem method,called when share button is pressed
    func shareItem()
    {
        // marking the file to be shared
        self.markItemSelected(fileArray[self.index])
        // get url for selected object
        let selectedUrl = appCoreData.getUrlsForSelectedObjects()
        print("selectedUrl.count -> \(selectedUrl.count)")
        // TODO: Look into 2° activities like copy, print, etc.
        let activityViewController = UIActivityViewController(activityItems: selectedUrl, applicationActivities: nil)
        self.navigationController?.presentViewController(activityViewController, animated: true) {}
        appCoreData.removeSelectTagForAllChildren()
    }
    
    func segueBack()
    {
        performSegueWithIdentifier("AVToHome", sender: self)
    }
    
    func addGestures()
    {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: "nextFile:")
        swipeLeft.direction = .Left
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: "prevFile:")
        swipeRight.direction = .Right
        
        self.view.addGestureRecognizer(swipeLeft)
        self.view.addGestureRecognizer(swipeRight)
    
    }
    


    
    func fetch(url: NSURL)
    {
        self.player = AVPlayer(URL: url)
    }
    
    func nextFile(gesture: UISwipeGestureRecognizer)
    {
        let tempIndex = index + 1
        if fileArray.count > tempIndex && tempIndex >= 0
        {
            index += 1
            chooseView(index)
        }
    }
    
    
    func prevFile(gesture: UISwipeGestureRecognizer)
    {
        let tempIndex = index - 1
        if fileArray.count > tempIndex && tempIndex >= 0
        {
            index -= 1
            chooseView(index)
        }
    }

    func chooseView(i: Int)
    {
        let fileObject = fileArray[i]
        let mimeClass = fileObject.mimetype?.group
        switch mimeClass!
        {
        case "audio", "video":
            self.title = fileObject.name
            self.fetch(fileObject.url!)

        case "image": performSegueWithIdentifier("AVToImage", sender: nil)
            
        default: performSegueWithIdentifier("AVToFile", sender: nil)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        switch segue.identifier!
        {
        case "AVToFile":
            if let fileViewController = segue.destinationViewController as? FileViewController
            {
                fileViewController.fileArray = fileArray
                fileViewController.index = index
                fileViewController.fileUrl = fileArray[index].url
            }

        case "AVToImage":
            if let ImageViewController = segue.destinationViewController as? ViewImageController
            {
                ImageViewController.fileArray = fileArray
                ImageViewController.index = index
            }
        case "DisplayMoveDestination":
            if let moveView = segue.destinationViewController as? MoveCopyViewController
            {
                moveView.calledAction = .Move
            }
            
        case "DisplayCopyDestination":
            if let copyView = segue.destinationViewController as? MoveCopyViewController
            {
                copyView.calledAction = .Copy
            }
        case "DisplaySearchView":
            segue.destinationViewController as? SearchViewController
    
        default:
            NSLog("No identifier found!")
            break
        }
    }


}
