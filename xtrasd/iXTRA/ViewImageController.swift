//
//  ViewImageController.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-10-13.
//  Copyright © 2015 iXTRA Technologies. All rights reserved.
//

// code borrowed from
// https://github.com/evgenyneu/ios-imagescroll-swift


import UIKit

class ViewImageController: UIViewController, UIScrollViewDelegate {
    //MARK: Properties
    var fileArray: [File]!
    var index: Int = 0
    var fileUrl: NSURL!

    var image:UIImage!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!

    
    @IBOutlet weak var imageConstraintTop: NSLayoutConstraint!
    @IBOutlet weak var imageConstraintRight: NSLayoutConstraint!
    @IBOutlet weak var imageConstraintLeft: NSLayoutConstraint!
    @IBOutlet weak var imageConstraintBottom: NSLayoutConstraint!
    
    var lastZoomScale: CGFloat = -1
    
    let fileManager = NSFileManager.defaultManager()
    let appCoreData = AppCoreData()
    
    
    @IBOutlet var menu: UIView!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // hide back button
        self.navigationItem.setHidesBackButton(true, animated: false)
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
    func markItemSelected(file:File)
    {
        // Add select tag to current file
        appCoreData.setSelectTagForChildFile(file)
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
        performSegueWithIdentifier("ImageToHome", sender: self)
    }

    
    func fetch(url: NSURL)
    {
        imageView.image = UIImage(contentsOfFile: url.path!)
        scrollView.delegate = self
        updateZoom()
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
        case "audio", "video": performSegueWithIdentifier("ImageToAV", sender: nil)
        case "image":
            self.title = fileObject.name
            self.fetch(fileObject.url!)
        default:
            performSegueWithIdentifier("ImageToFile", sender: nil)
        }
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        switch segue.identifier!
        {
        case "ImageToFile":
            if let fileViewController = segue.destinationViewController as? FileViewController
            {
                fileViewController.fileArray = fileArray
                fileViewController.index = index
                fileViewController.fileUrl = fileArray[index].url!
            }
        case "ImageToAV":
            if let AVViewController = segue.destinationViewController as? AVMediaController
            {
                AVViewController.fileArray = fileArray
                AVViewController.index = index
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

    // Update zoom scale and constraints with animation.
    @available(iOS 8.0, *)
    override func viewWillTransitionToSize(size: CGSize,
        withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            
            super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
            
            coordinator.animateAlongsideTransition({ [weak self] _ in
                self?.updateZoom()
                }, completion: nil)
    }
    
    
    func updateConstraints() {
        if let image = imageView.image {
            let imageWidth = image.size.width
            let imageHeight = image.size.height
            
            let viewWidth = scrollView.bounds.size.width
            let viewHeight = scrollView.bounds.size.height
            
            // center image if it is smaller than the scroll view
            var hPadding = (viewWidth - scrollView.zoomScale * imageWidth) / 2
            if hPadding < 0 { hPadding = 0 }
            
            var vPadding = (viewHeight - scrollView.zoomScale * imageHeight) / 2
            if vPadding < 0 { vPadding = 0 }
            
            imageConstraintLeft.constant = hPadding
            imageConstraintRight.constant = hPadding
            
            imageConstraintTop.constant = vPadding
            imageConstraintBottom.constant = vPadding
            
            view.layoutIfNeeded()
        }
    }
    
    // Zoom to show as much image as possible unless image is smaller than the scroll view
    private func updateZoom() {
        if let image = imageView.image {
            var minZoom = min(scrollView.bounds.size.width / image.size.width,
                scrollView.bounds.size.height / image.size.height)
            
            if minZoom > 1 { minZoom = 1 }
            
            scrollView.minimumZoomScale = minZoom
            
            // Force scrollViewDidZoom fire if zoom did not change
            if minZoom == lastZoomScale { minZoom += 0.000001 }
            
            scrollView.zoomScale = minZoom
            lastZoomScale = minZoom
        }
    }
    
   
    // UIScrollViewDelegate
    // -----------------------
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        updateConstraints()
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }

}
