//
//  StorageViewController.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-08-18.
//  Copyright (c) 2015 iXTRA Technologies. All rights reserved.
//

import Foundation
import UIKit
import XTR100
//import ImageIO
import AVKit
import AVFoundation
import CoreData
import Photos
import MobileCoreServices
import CloudKit

class PeripheralViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SWTableViewCellDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, AVAudioPlayerDelegate, UIGestureRecognizerDelegate, CTAssetsPickerControllerDelegate,CustomOverlayDelegate
{
    
    // MARK: Properties
    
    // scene objects
    @IBOutlet weak var overlayAddMenu: UIView!
    @IBOutlet weak var overlayMenu: UIView!
    @IBOutlet weak var overlaySettingsMenu: UIView!
    @IBOutlet weak var overlayTapLayer: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
//    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noFolderFoundNotice: UIView!

    @IBOutlet var defaultActionView: SingleFileActionView!
    @IBOutlet var audioActionView: SingleFileActionView!
    var actionMenuCellIndexPath: NSIndexPath!
    var leftBarButtonItems: [UIBarButtonItem]?
    
    // constants
    let folderCellIdentifier = "folderCell"
    let cellHeightScaler: CGFloat = 0.45
    let cellSeparatorHeight: CGFloat = 1.0
    let divisorConstant: CGFloat = 2.364
    // handlers
    let lib = Library()
    let fileManager = NSFileManager.defaultManager()
    let appCoreData = AppCoreData()
    var preferences: Preferences!
    
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    var editingMode: Bool = false
 
    
    var currentDirUrl: NSURL!
    var rootUrl: NSURL!
    var xtr100Url: AnyObject!
    
    // core data fetch holders
    var parent: Directory!
    var dirArray:[Directory] = []
    var fileArray: [File] = []
    
    // controls
    var refreshControl: UIRefreshControl!
    
    // constant values
    //let defaultMenuBackgroundColour: UIColor = UIColor.whiteColor()
    let defaultMenuBackgroundColour: UIColor = UIColor.clearColor()
    let alphaValue:CGFloat = 0.85
    
    var imagePicker = UIImagePickerController()
    
    var photoCaptureMode: Bool = true
    var isRecording: Bool = false //Used to check whether video recording is in progress
    
    var reachability:Reachability! // Used to check internet connection
    var activityIndicator: UIActivityIndicatorView!
    var arrayResults:NSMutableArray! // Used to store the data returned by iCloud
    var morePressed: Bool = false

    var isListSortedByFavourite:Bool! = false //Used to check if the list is being sorted by favourites
    
    
    // MARK: View functions

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // set navigationBar tint colour
        self.navigationController?.navigationBar.tintColor = UIColor.darkTextColor()
        
        //Initiate Reachability
        let hostName:String? = "google.com"
        
        //Initiate activity indicator
        //Add activity indicator
        self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        self.activityIndicator.center = self.view.center // CGRectMake(self.view.frame.size.width/2 - 15, self.view.frame.size.height/2 - 15, 30, 30)
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.hidden = true
        self.view.addSubview(activityIndicator)
        
        do {
            let reachability = try hostName == nil ? Reachability.reachabilityForInternetConnection() : Reachability(hostname: hostName!)
            self.reachability = reachability
        } catch ReachabilityError.FailedToCreateWithAddress(let address) {
           print("Unable to create\nReachability with address:\n\(address)")
            return
        } catch {}
        
        
        // setup refresh control
        refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: "handleRefresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        // add long-press gesture to collection view
//        let longpressGesture = UILongPressGestureRecognizer.init(target: self, action: "activateMenuForSelectedCollectionViewCell:")
//        longpressGesture.delegate = self
//        self.collectionView.addGestureRecognizer(longpressGesture)
        
        // on load multiple selection should be turned off
        self.collectionView.allowsMultipleSelection = false
        // add toolbar if we're still in editing mode otherwise hide it
        self.navigationController?.toolbarHidden = (editingMode) ? false : true
//        // UICollectionView Layout
//        self.collectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
//        self.collectionViewFlowLayout.itemSize = CGSize(width: 75, height: 90)
        
        // get preferences
        self.preferences = appCoreData.fetchPreferences()
        
        // check if the user has set a default sort view
        /* 
        1. if so order the list of folders and files according to the preference
        2. otherwise, use default sort -> Alphabetical
        */

    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        var label: String?
        
        if currentDirUrl != rootUrl
        {
            label = currentDirUrl?.lastPathComponent
        }
        else
        {
            label = "HOME"
        }
        
        self.navigationItem.title = label?.uppercaseString
        self.navigationController?.toolbarHidden  = true
        // populate the table with enumerated url
        self.populateTable()
//        self.refresh()
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
    }
    
    // MARK: Datasource
    func populateTable()
    {
        // if we have an accessory then populate the table data
        accessoryIsConnected = true
        if accessoryIsConnected
        {
            
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
            
            // get listing of file objects from core data
            self.fetchObjectsOfCurrentDir(currentDirUrl)
            
            //check persistentfilter
            if self.preferences.persistentFilter
            {
                print("user has persistent filter -> On")
                // apply filter to file list
                self.applyFilter(self.preferences.persistentFilterMode)
            }
            
            self.collectionView.reloadData()
            self.tableView.reloadData()
        }
        else
        {
            // we are not connected to a peripheral
            let uiAlert = UIAlertController(title: "ALERT", message: "Please connect the XTR100 peripheral", preferredStyle: .Alert)
            uiAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(uiAlert, animated: true, completion: nil)
            
        }
        
    }
 
    func fetchObjectsOfCurrentDir(url: NSURL)
    {
        // initiate link to core data Directory table
        let dirEntity = NSEntityDescription.entityForName("Directory", inManagedObjectContext: context)
        let request = NSFetchRequest()
        request.entity = dirEntity
        // specify how we want the results to be sorted
        var sortDescriptors: [NSSortDescriptor] = []
        
        self.isListSortedByFavourite = false
        
        if self.preferences.isDefaultSortSet
        {
            sortDescriptors = preferences.getDefaultSort
        }
        else
        {
            sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        }

        let sortPattern: Preferences.DefaultSort = preferences.defaultSort
        
        switch sortPattern
        {
        case .StarredAlphabetical:
            print("Favourties sort")
            self.isListSortedByFavourite = true
        case .StarredRecent:
            print("Favourties sort")
            self.isListSortedByFavourite = true
        default:
            print("Not favourite Sort")
            self.isListSortedByFavourite = false
        }

        request.sortDescriptors = sortDescriptors
        
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
                
                self.dirArray = parent.hasDirectories?.sortedArrayUsingDescriptors(sortDescriptors) as! [Directory]
                // from CoreData get array of files belonging to rootUrl
                self.fileArray = parent.hasFiles!.sortedArrayUsingDescriptors(sortDescriptors) as! [File]
                print("result ->\(parent.name)")
                print("dirArray.count -> \(dirArray.count)")
                print("fileArray.count ->\(fileArray.count)")
            }
            
        } catch {
            print("error in fetch \(error)")
        }

    }

    // MARK: refresh functions
    func handleRefresh(refreshControl: UIRefreshControl)
    {
        //DEBUG
        accessoryIsConnected = true
        
        self.refresh()
        self.refreshControl!.endRefreshing()
    }
    
    // Refresh tableview
    func refresh()
    {

        self.removeSubviews()
        self.populateTable()

    }

    //MARK: TableView Definitions
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return accessoryIsConnected ? fileArray.count : 1
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        
        let builtCell: SWTableViewCell!
        let normalFileCellIdentifier = "fileCell"
        let imageFileCellIdentifier = "imageCell"
        let videoFileCellIdentifier = "videoCell"
        let audioFileCellIdentifier = "audioCell"
        
        let object = fileArray[indexPath.row]

        let url = fileArray[indexPath.row].url!
        
        let mimeClass = lib.getMimeClass(url)
    
        switch mimeClass
        {
        case "image":
            let dequeued  = self.tableView.dequeueReusableCellWithIdentifier(imageFileCellIdentifier)
            let cell = dequeued as! ImageTableViewCell

            cell.previewImage.image = UIImage(contentsOfFile: url.path!)
            cell.previewImage.frame = cell.contentView.bounds
            cell.previewImage.contentMode = .ScaleAspectFill
            cell.previewImage.sizeToFit()
            
            //check if tableView is in edit mode
            if(self.tableView.editing)
            {
                //Show select circle
                cell.activateTableViewCellSelection(true)
                object.isSelected.boolValue ? cell.cellSelection.setCheckedCell(true) : cell.cellSelection.setCheckedCell(false)
            }
            else
            {
                //Hide Select Circle
                cell.activateTableViewCellSelection(false)
            }
            
            //Check if the default sort is set
            if(self.isListSortedByFavourite.boolValue)
            {
                if(object.isStarred.boolValue)
                {
                    cell.starImage.hidden = false
                }
                else
                {
                    cell.starImage.hidden = true
                }
            }
            else
            {
                cell.starImage.hidden = true
            }
            
            builtCell = cell
        case "video":
            let dequeued  = self.tableView.dequeueReusableCellWithIdentifier(videoFileCellIdentifier)
            let cell = dequeued as! VideoTableViewCell
            cell.movieController.player = AVPlayer(URL: url)

            cell.movieController.view.frame = cell.contentView.bounds
            cell.movieController.view.sizeToFit()
            cell.movieController.videoGravity  = AVLayerVideoGravityResizeAspectFill
            cell.movieController.showsPlaybackControls = false
//            cell.togglePlayStopButtons()
            cell.contentView.insertSubview(cell.movieController.view, atIndex: 0)
            
            // Added check to allow userInteration if selection mode is disabled
            if editingMode == true{
                cell.playButton.userInteractionEnabled = false
            }
            else{
                cell.playButton.userInteractionEnabled = true
            }

            //check if tableView is in edit mode
            if(self.tableView.editing)
            {
                //Show select circle
                cell.activateTableViewCellSelection(true)
                object.isSelected.boolValue ? cell.cellSelection.setCheckedCell(true) : cell.cellSelection.setCheckedCell(false)
            }
            else
            {
                //Hide Select Circle
                cell.activateTableViewCellSelection(false)
            }
            
            //Check if the default sort is set
            if(self.isListSortedByFavourite.boolValue)
            {
                if(object.isStarred.boolValue)
                {
                    cell.starImage.hidden = false
                }
                else
                {
                    cell.starImage.hidden = true
                }
            }
            else
            {
                cell.starImage.hidden = true
            }
            
            builtCell = cell
        case "audio":
            let dequeued  = self.tableView.dequeueReusableCellWithIdentifier(audioFileCellIdentifier)
            let cell = dequeued as! AudioTableViewCell
            do
            {
                try cell.audioPlayer = AVAudioPlayer(contentsOfURL: url)
                cell.audioPlayer?.delegate = self
                cell.audioPlayer?.prepareToPlay()
                cell.bringSubviewToFront(cell.play)
                cell.play.hidden = false
                cell.stop.hidden = true
                cell.fileName.text = url.lastPathComponent
                cell.fileObject = fileArray[indexPath.row]
                
                //check if tableView is in edit mode
                if(self.tableView.editing)
                {
                    //Show select circle
                    cell.activateTableViewCellSelection(true)
                    object.isSelected.boolValue ? cell.cellSelection.setCheckedCell(true) : cell.cellSelection.setCheckedCell(false)
                }
                else
                {
                    //Hide Select Circle
                    cell.activateTableViewCellSelection(false)
                }
            }
            catch
            {
                print("audioplayer encountered an error -> \(error)")
            }
            
//            cell.textLabel!.text = url.lastPathComponent

            //Check if the default sort is set
            if(self.isListSortedByFavourite.boolValue)
            {
                if(object.isStarred.boolValue)
                {
                    cell.starImage.hidden = false
                }
                else
                {
                    cell.starImage.hidden = true
                }
            }
            else
            {
                cell.starImage.hidden = true
            }
            
            builtCell = cell
        default:
            let dequeued  = self.tableView.dequeueReusableCellWithIdentifier(normalFileCellIdentifier)
            let cell = dequeued as! FileTableViewCell
            cell.fileContentView.loadRequest(NSURLRequest(URL: url))
            cell.fileContentView.frame = self.tableView.rectForRowAtIndexPath(indexPath)
            cell.fileContentView.autoresizingMask = .None
            
            //check if tableView is in edit mode
            if(self.tableView.editing)
            {
                //Show select circle
                cell.activateTableViewCellSelection(true)
                object.isSelected.boolValue ? cell.cellSelection.setCheckedCell(true) : cell.cellSelection.setCheckedCell(false)
            }
            else
            {
                //Hide Select Circle
                cell.activateTableViewCellSelection(false)
            }
            
            //Check if the default sort is set
            if(self.isListSortedByFavourite.boolValue)
            {
                if(object.isStarred.boolValue)
                {
                    cell.starImage.hidden = false
                }
                else
                {
                    cell.starImage.hidden = true
                }
            }
            else
            {
                cell.starImage.hidden = true
            }
            
            builtCell = cell
        }
        
        // add left/right swipe functionality
        builtCell.leftUtilityButtons = self.leftButtons() as [AnyObject]
        builtCell.rightUtilityButtons = self.rightButtons() as [AnyObject]
        builtCell.delegate = self
        // remove any accessory
        builtCell.accessoryType = UITableViewCellAccessoryType.None
        
        // update view constraints
        builtCell.setNeedsUpdateConstraints()
        builtCell.updateConstraintsIfNeeded()

        return builtCell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var height: CGFloat = 40.0

        let object = fileArray[indexPath.row]
        let mimeClass = object.mimetype?.group
        
        switch mimeClass!
        {
            
        case "audio": height = 80.0
        case "image", "video": height = self.view.bounds.size.width * cellHeightScaler + cellSeparatorHeight
        default: height = 140

        }

        return height
    }
    
   func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .None
    }
    
    func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    // what to do when a row is tapped by the user. If it's a directory enter, if it's a file read
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if !self.tableView.editing
        {
            // grab our current url
            let selectedUrl = fileArray[indexPath.row].url
            // check if the object is a directory
            // view file
            let mimeClass = lib.getMimeClass(selectedUrl!)
            switch mimeClass
            {
            case "image": performSegueWithIdentifier("ShowImage", sender: indexPath)
            case "video": performSegueWithIdentifier("ShowVideoMedia", sender: indexPath)
            case "audio": performSegueWithIdentifier("ShowAudioMedia", sender: indexPath)
            default: performSegueWithIdentifier("ShowContentsOfFile", sender: indexPath)
            }
        }
        else
        {
            let child = fileArray[indexPath.row]
            
            //Get selected cell
            let indexPath = tableView.indexPathForSelectedRow
            
            let url = fileArray[indexPath!.row].url!
            let mimeClass = lib.getMimeClass(url)
            
            switch mimeClass
            {
            case "image":
                let selectedCell = tableView.cellForRowAtIndexPath(indexPath!) as! ImageTableViewCell

                //Check/Uncheck cell based on whether it is already checked
                if(selectedCell.cellSelection.checked)
                {
                    appCoreData.removeSelectTagForChildFile(child)
                    selectedCell.cellSelection.setCheckedCell(false)
                }
                else
                {
                    selectedCell.cellSelection.setCheckedCell(true)
                    appCoreData.setSelectTagForChildFile(child)
                    
                }
                
            case "video":
                let selectedCell = tableView.cellForRowAtIndexPath(indexPath!) as! VideoTableViewCell

                //Check/Uncheck cell based on whether it is already checked
                if(selectedCell.cellSelection.checked)
                {
                    appCoreData.removeSelectTagForChildFile(child)
                    selectedCell.cellSelection.setCheckedCell(false)
                }
                else
                {
                    selectedCell.cellSelection.setCheckedCell(true)
                    appCoreData.setSelectTagForChildFile(child)
                    
                }
                
            case "audio":
                let selectedCell = tableView.cellForRowAtIndexPath(indexPath!) as! AudioTableViewCell

                //Check/Uncheck cell based on whether it is already checked
                if(selectedCell.cellSelection.checked)
                {
                    appCoreData.removeSelectTagForChildFile(child)
                    selectedCell.cellSelection.setCheckedCell(false)
                }
                else
                {
                    selectedCell.cellSelection.setCheckedCell(true)
                    appCoreData.setSelectTagForChildFile(child)
                    
                }
                
            default:
                let selectedCell = tableView.cellForRowAtIndexPath(indexPath!) as! FileTableViewCell

                //Check/Uncheck cell based on whether it is already checked
                if(selectedCell.cellSelection.checked)
                {
                    appCoreData.removeSelectTagForChildFile(child)
                    selectedCell.cellSelection.setCheckedCell(false)
                }
                else
                {
                    selectedCell.cellSelection.setCheckedCell(true)
                    appCoreData.setSelectTagForChildFile(child)
                    
                }
            }
        }
    }

    // MARK: Gesture interaction
    /*
     * Code credit goes to: 
     * Author: Christopher Wendel
     * Project: SWTableViewCell
     * URL: https://github.com/CEWendel/SWTableViewCell
    */
    func rightButtons() -> NSArray
    {
        let rightUtilityButtons = NSMutableArray()
        rightUtilityButtons.sw_addUtilityButtonWithColor(UIColor(red:57.0/255.0,green:73/255, blue:88/255,alpha:1.0), icon: UIImage(named:"TableMore"))
        
        return rightUtilityButtons
    }
    
    func leftButtons() -> NSArray
    {
        let leftUtilityButtons = NSMutableArray()
        leftUtilityButtons.sw_addUtilityButtonWithColor(UIColor(red: 238/255, green: 80/255, blue: 79/255, alpha: 1.0), icon: UIImage(named: "TableDelete"))
        return leftUtilityButtons
    }
    // What to do when user swipes a table row from right to left
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex index: Int)
    {
        let cellIndexPath:NSIndexPath = self.tableView.indexPathForCell(cell)!

        switch index
        {
        case 0:
            print("more button pressed")
            
            // changing morePressed parameter value to true to disable swipe on cell
            morePressed = true
            swipeableTableViewCell(cell, canSwipeToState: SWCellState.CellStateLeft)        // changing left swipe state
            swipeableTableViewCell(cell, canSwipeToState: SWCellState.CellStateRight)   // changing right swipe state
            
            // first hide the utility button
            cell.hideUtilityButtonsAnimated(true)
            // get the cell
            actionMenuCellIndexPath = cellIndexPath
            print("cell height smit: \(cell.contentView.bounds.size.height)")
            let subview: UIView =  (cell.contentView.bounds.size.height > 80) ? self.defaultActionView : self.audioActionView
            subview.frame = CGRectMake(cell.contentView.bounds.minX, cell.contentView.bounds.minY, cell.contentView.bounds.size.width, cell.contentView.bounds.size.height)
            
            let overlayTap = UITapGestureRecognizer.init(target: self, action: "onActionMenuTapped:")
            subview.addGestureRecognizer(overlayTap)

            cell.contentView.addSubview(subview)
            cell.contentView.bringSubviewToFront(subview)
            
            appCoreData.setSelectTagForChildFile(fileArray[cellIndexPath.row])
            // pass the object of the cell to the view, this will always apply to File
            // present view within cell view
            
//            self.menuForSelectedCell(fileArray[cellIndexPath.row], objectType: .File)
            
         default: print("no selection")
        }
    }
    
    // What to do when the user swipes a table row from left to right
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerLeftUtilityButtonWithIndex index: Int)
    {
        switch index
        {
        case 0:
            print("delete button pressed")
            let cellIndexPath:NSIndexPath = self.tableView.indexPathForCell(cell)!

            do
            {
                try self.fileManager.removeItemAtURL(fileArray[cellIndexPath.row].url!)
                // TODO: remove url from core data currentDirUrl.hasFiles
                appCoreData.deleteChildFile(fileArray[cellIndexPath.row])
                fileArray.removeAtIndex(cellIndexPath.row)
                
            }
            catch let error as NSError
            {
                print("Item deletion failed -> \(error)")
            }
            self.tableView.deleteRowsAtIndexPaths([cellIndexPath], withRowAnimation: .Automatic)
        default: print("no selection")
        }
    }
    
    @IBAction func copyItemButton(sender: AnyObject)
    {
        print("copyItemButton pressed")
        self.copyItems()
        self.removeActionMenu()
    }
    
    @IBAction func moveItemButton(sender: AnyObject)
    {
        print("moveItemButton pressed")
        self.moveItems()
        self.removeActionMenu()
    }
    
    @IBAction func shareItemButton(sender: AnyObject)
    {
        print("shareItemButton pressed")
        self.selectShareDestination()
        self.removeActionMenu()
    }
    
    @IBAction func starItemButton(sender: AnyObject)
    {
        print("starItemButton pressed")
        self.starItems()
        self.removeActionMenu()
    }
    
    @IBAction func renameItemButton(sender: AnyObject)
    {
        print("renameItemButton pressed")

        self.renameItem()
        self.removeActionMenu()
    }
    
    @IBAction func cancelActionMenu(sender: AnyObject)
    {
        print("cancelActionMenu button pressed on row -> \(actionMenuCellIndexPath.row)")
        self.removeActionMenu()
    }
    
    func removeActionMenu()
    {
        // remove subview
        let cell = self.tableView.cellForRowAtIndexPath(actionMenuCellIndexPath)
        (defaultActionView.superview == cell!.contentView) ? defaultActionView.removeFromSuperview() : audioActionView.removeFromSuperview()
        
        // changing morePressed Parameter to enable cell swipe
        morePressed = false
        
        // deselect objects
//        appCoreData.removeSelectTagForChildFile(fileArray[actionMenuCellIndexPath.row])

    }
    
    func onActionMenuTapped(gesture: UIGestureRecognizer)
    {
        self.view.removeGestureRecognizer(gesture)
        self.removeActionMenu()
    }
    // Disable swiping multiple rows
    func swipeableTableViewCellShouldHideUtilityButtonsOnSwipe(cell: SWTableViewCell!) -> Bool
    {
        return true
    }
    
    
    // MARK: Colleciton view
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int
    {
    return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return (dirArray.count > 0) ? dirArray.count : 1
      }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(folderCellIdentifier, forIndexPath: indexPath) as! FolderCollectionViewCell
        
        
        // when we have directories to show create the cells, otherwise display a notification
        if dirArray.count > 0
        {
            // make sure that the notification is removed
            self.noFolderFoundNotice.removeFromSuperview()
            
            let object = dirArray[indexPath.row]
            let data: NSURL = object.url!

            
            cell.icon.image = UIImage(named: "folder")
            cell.folderName.text = data.lastPathComponent
            if self.collectionView.allowsMultipleSelection
            {
                print("cell selection activated")
                cell.activateCellSelection(true)
                object.isSelected.boolValue ? cell.cellSelection.setCheckedCell(true) : cell.cellSelection.setCheckedCell(false)
            }
            else
            {
                print("cell selection not activated")
                cell.activateCellSelection(false)
            }
            
            //Check if the default sort is set
            if(self.isListSortedByFavourite.boolValue)
            {
                if(object.isStarred.boolValue)
                {
                    cell.starImage.hidden = false
                }
                else
                {
                    cell.starImage.hidden = true
                }
            }
            else
            {
                cell.starImage.hidden = true
            }

        }
        else
        {
            // we have nothing to show, therefore return an empty cell
            cell.icon.image = nil
            cell.folderName.text = ""
            cell.activateCellSelection(false)
            self.noFolderFoundNotice.frame = CGRectMake(0,0, self.view.bounds.size.width, 110)
            self.collectionView.addSubview(self.noFolderFoundNotice)
        }

        return cell
    }

    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        if (self.collectionView.allowsMultipleSelection)
        {
            print("cell -> \(indexPath.row) marked")
            let selectedFolder = dirArray[indexPath.row]
            appCoreData.setSelectTagForChildDir(selectedFolder)
            let cell = self.collectionView.cellForItemAtIndexPath(indexPath) as! FolderCollectionViewCell
            cell.cellSelection.setCheckedCell(true)
        }

    }

    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath)
    {
        if (self.collectionView.allowsMultipleSelection)
        {
            print("cell -> \(indexPath.row) unmarked")
            let selectedFolder = dirArray[indexPath.row]
            appCoreData.removeSelectTagForChildDir(selectedFolder)
            let cell = self.collectionView.cellForItemAtIndexPath(indexPath) as! FolderCollectionViewCell
            cell.cellSelection.setCheckedCell(false)
        }
    }
    

    // MARK: User interaction
    @IBAction func showCamera(sender: AnyObject)
    {
        self.removeSubviews()
        self.captureMedia()
    }
    
    @IBAction func showSettingsMenu(sender: AnyObject)
    {
        var isSameMenuSelected: Bool = false
        
        // check if any subview is displayed
        if (overlayTapLayer.superview == self.view)
        {
            for subview in overlayTapLayer.subviews
            {
                if(subview .isEqual(overlaySettingsMenu))
                {
                    isSameMenuSelected = true
                }
            }
            
            if(isSameMenuSelected)
            {
                // if the same subview is displayed, remove it
                overlaySettingsMenu.removeFromSuperview()
            }
            else
            {
                // if some other menu is selected, remove the displayed menu and setup selected menu
                self.setupOverlayLayer(overlaySettingsMenu)
            }
        }
        else
        {
            // register tap gesture recognizer to dismiss overlay menu when user taps on the screen
            self.setupOverlayLayer(overlaySettingsMenu)

        }

    }
    
    @IBAction func showMenu(sender: AnyObject)
    {
        var isSameMenuSelected: Bool = false
        
        // check if any subview is displayed
        if (overlayTapLayer.superview == self.view)
        {
            for subview in overlayTapLayer.subviews
            {
                if(subview .isEqual(overlayMenu))
                {
                    isSameMenuSelected = true
                }
            }
            
            if(isSameMenuSelected)
            {
                // if the same subview is displayed, remove it
                overlayMenu.removeFromSuperview()
            }
            else
            {
                // if some other menu is selected, remove the displayed menu and setup selected menu
                self.setupOverlayLayer(overlayMenu)
            }
        }
        else
        {
            // register tap gesture recognizer to dismiss overlay menu when user taps on the screen
            self.setupOverlayLayer(overlayMenu)
            
        }
    }
    
    @IBAction func showAddMenu(sender: AnyObject)
    {
        var isSameMenuSelected: Bool = false
        
        // check if any subview is displayed
        if (overlayTapLayer.superview == self.view)
        {
            for subview in overlayTapLayer.subviews
            {
                if(subview .isEqual(overlayAddMenu))
                {
                    isSameMenuSelected = true
                }
            }
            
            if(isSameMenuSelected)
            {
                // if the same subview is displayed, remove it
                overlayAddMenu.removeFromSuperview()
            }
            else
            {
                // if some other menu is selected, remove the displayed menu and setup selected menu
                self.setupOverlayLayer(overlayAddMenu)
            }
        }
        else
        {
            // register tap gesture recognizer to dismiss overlay menu when user taps on the screen
            self.setupOverlayLayer(overlayAddMenu)
            
        }
    }
    
    func setupOverlayLayer(overlay: UIView)
    {
        let overlayTap = UITapGestureRecognizer.init(target: self, action: "onOverlayTapped:")
        overlayTapLayer.frame = self.view.bounds
        for subview in overlayTapLayer.subviews { subview.removeFromSuperview() }
        overlayTapLayer.addGestureRecognizer(overlayTap)
//        overlayTapLayer.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(alphaValue)
        overlayTapLayer.backgroundColor = UIColor.clearColor()
        self.view.addSubview(overlayTapLayer)
        overlayTapLayer.layer.zPosition = 1
        tableView.scrollEnabled = false
        
//        overlaySettingsMenu.backgroundColor = defaultMenuBackgroundColour
        
        //size the overlay for menu to our current view
        overlay.frame = CGRectMake(0,0, self.view.bounds.size.width, self.view.bounds.size.height/divisorConstant)
        overlayTapLayer.addSubview(overlay)
        
    }
    
    func onOverlayTapped(gesture:UITapGestureRecognizer)
    {
        self.view.removeGestureRecognizer(gesture)
        self.removeSubviews()
        
    }
    
    func removeSubviews()
    {
        overlayTapLayer.removeFromSuperview()
        tableView.scrollEnabled = true
    }
    
    //Show Action Sheet to select source
    @IBAction func addFiles(sender: AnyObject) {
        
        self.removeSubviews()
        
        // create alert container
        let alertController = UIAlertController(title:nil, message:nil, preferredStyle: .ActionSheet)
        // define Photo Gallery
        let photoGalleryMenu = UIAlertAction(title: "Photos", style: .Default, handler: { (action: UIAlertAction) -> Void in
            
            self.selectImageFromLibrary()
            
        })
        
        // define iCloud
        let iCloudMenu = UIAlertAction(title: "iCloud", style: .Default, handler: { (action: UIAlertAction) -> Void in
            
            self.addFromCloud()
            
        })
        
        //define cancel
        let cancel = UIAlertAction(title: "Cancel", style: .Destructive, handler: nil)
        
        // assemble alert optins
        alertController.addAction(photoGalleryMenu)
        alertController.addAction(iCloudMenu)
        alertController.addAction(cancel)
        
        // present the alert view to the user
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    //Upload Files to Cloud
    func uploadToCloud()
    {
        let selectedFileURL: NSURL! = appCoreData.getUrlsForSelectedObjects()[0]
        
        if(self.reachability.isReachable())
        {
            //Internet connection present
            
            //Check for selected file
            if(selectedFileURL != nil)
            {
                let selectedFileName: NSString! = selectedFileURL.lastPathComponent
                
                //Check for iCloud accounts
                CKContainer.defaultContainer().accountStatusWithCompletionHandler({ (accountStatus, error) -> Void in
                    if (accountStatus == CKAccountStatus.NoAccount) {
                        //No account found
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            let alert = UIAlertController(title: "Sign in to iCloud", message: "Sign in to your iCloud account to upload files. On the Home screen, launch Settings, tap iCloud, and enter your Apple ID. Turn iCloud Drive on. If you don't have an iCloud account, tap Create a new Apple ID.", preferredStyle: UIAlertControllerStyle.Alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                            self.presentViewController(alert, animated: true, completion:nil)
                        })
                        
                    }
                    else {
                        //Account present
                        
                        //Create record
                        var fileRecord: CKRecord!
                        let timestampAsString = String(format: "%f", NSDate.timeIntervalSinceReferenceDate())
                        let timestampParts = timestampAsString.componentsSeparatedByString(".")
                        let fileID = CKRecordID(recordName: timestampParts[0])
                        
                        fileRecord = CKRecord(recordType: "Files", recordID: fileID)
                        
                        fileRecord.setObject(selectedFileName, forKey: "fileName")
                        
                        let fileExtension = selectedFileName.pathExtension as CFStringRef
                        
                        let unmanagedFileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil)
                        let fileUTI = unmanagedFileUTI!.takeRetainedValue()
                        
                        var fileText:NSString!
                        
                        if (UTTypeConformsTo(fileUTI, kUTTypeText))
                        {
                            do {
                                fileText = try String(contentsOfFile:selectedFileURL.path! , encoding: NSUTF8StringEncoding)
                                
                               
                            } catch let error as NSError {
                                print("Cannot write to file -> error: \(error)")
                            }
                            if(fileText.length != 0)
                            {
                                fileRecord.setObject(fileText, forKey: "fileText")
                            }
                            else
                            {
                                fileRecord.setObject("default text", forKey: "fileText")
                            }
                        }
                        else
                        {
                            fileRecord.setObject("media", forKey: "fileText")
                        }
                        
                        let asset = CKAsset(fileURL: selectedFileURL)
                        fileRecord.setObject(asset, forKey: "file")
                        
                        //Upload record
                        let container = CKContainer.defaultContainer()
                        let privateDatabase = container.privateCloudDatabase
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            //Disable user interaction
                            UIApplication.sharedApplication().beginIgnoringInteractionEvents()
                            
                            self.activityIndicator.hidden = false
                            self.activityIndicator.startAnimating()
                        })
                        
                        privateDatabase.saveRecord(fileRecord, completionHandler: { (record, error) -> Void in
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                                self.activityIndicator.stopAnimating()
                            })
                            
                            if (error != nil) {
                                print(error)
                                dispatch_async(dispatch_get_main_queue(), {
                                    
                                    let alert = UIAlertController(title: "Failure!", message: "An Error Occurred.", preferredStyle: UIAlertControllerStyle.Alert)
                                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                                    self.presentViewController(alert, animated: true, completion:nil)
                                    
                                })
                            }
                            else {
                                print(record)
                                dispatch_async(dispatch_get_main_queue(), {
                                    
                                    let alert = UIAlertController(title: "Success!", message: "File was successfully uploaded to iCloud.", preferredStyle: UIAlertControllerStyle.Alert)
                                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                                    self.presentViewController(alert, animated: true, completion:nil)
                                })
                            }
                        })
                    }
                })
            }
        }
        else
        {
            //No internet connection
            dispatch_async(dispatch_get_main_queue(), {
                
                let alert = UIAlertController(title: "Error!", message: "No internet connection.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion:nil)
                
            })
        }
        
    }
    
    //Fetch files from Cloud
    func addFromCloud()
    {
        if(self.reachability.isReachable())
        {
            //Internet connection present
            
            //Check for iCloud Accounts
            CKContainer.defaultContainer().accountStatusWithCompletionHandler({ (accountStatus, error) -> Void in
                if (accountStatus == CKAccountStatus.NoAccount) {
                    //No account found
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        let alert = UIAlertController(title: "Sign in to iCloud", message: "Sign in to your iCloud account to download files. On the Home screen, launch Settings, tap iCloud, and enter your Apple ID. Turn iCloud Drive on. If you don't have an iCloud account, tap Create a new Apple ID.", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                        self.presentViewController(alert, animated: true, completion:nil)
                    })
                    
                }
                else {
                    //Account found
                    
                    self.arrayResults = NSMutableArray()
                    
                    //Download file
                    let container = CKContainer.defaultContainer()
                    let privateDatabase = container.privateCloudDatabase
                    let predicate = NSPredicate(value: true)
                    
                    let query = CKQuery(recordType: "Files", predicate: predicate)
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        //Disable user interaction
                        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
                        self.activityIndicator.hidden = false
                        self.activityIndicator.startAnimating()
                    })
                    
                    //Create operation
                    let operation = CKQueryOperation(query: query)
                    operation.desiredKeys = ["fileName", "file","fileText"]
                    operation.resultsLimit = 50

                    operation.qualityOfService = .UserInitiated

                    var resultFileName:String!
                    var resultFile:CKAsset!
                    var resultFileText:String!
                    
                    //Fetching the records
                    operation.recordFetchedBlock = { (record) in
                        let dictResult:NSMutableDictionary! = NSMutableDictionary()
                        
                        resultFileName = record["fileName"] as! String
                        resultFile = record["file"] as! CKAsset
                        resultFileText = record["fileText"] as! String
                        
                        dictResult.setValue(resultFileName, forKey: "resultFileName")
                        dictResult.setValue(resultFile, forKey: "resultFile")
                        dictResult.setValue(resultFileText, forKey: "resultFileText")

                        self.arrayResults.addObject(dictResult)
                    }
                
                    operation.queryCompletionBlock = { [unowned self] (cursor, error) in
                        
                        print("array: \(self.arrayResults), count: \(self.arrayResults.count)")
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            
                            //Disable user interaction
                            UIApplication.sharedApplication().endIgnoringInteractionEvents()
                            self.activityIndicator.stopAnimating()

                            // give it a destination
                            var localImagePathUrl:NSURL!
                            var mediaParent:Directory!
                            if error == nil
                            {
                                if(self.arrayResults.count>0)
                                {
                                    for object in self.arrayResults
                                    {
                                        let resultDict = object as! NSDictionary
                                        
                                        let resultFile = resultDict.objectForKey("resultFile") as! CKAsset
                                        let resultFileText = resultDict.objectForKey("resultFileText") as! String
                                        let resultFileName = resultDict.objectForKey("resultFileName") as! NSString
                                        let fileName = self.lib.isoDate()+(resultFileName as String)
                                        let fileExtension = resultFileName.pathExtension as CFStringRef
                                        
                                        let unmanagedFileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil)
                                        let fileUTI = unmanagedFileUTI!.takeRetainedValue()
                                        
                                        if (UTTypeConformsTo(fileUTI, kUTTypeText))
                                        {
                                            //For text files
                                            
                                            var paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask, true)
                                            let iOSApplicationDirectory: AnyObject = paths[0]
                                            
                                            let documentsPath = NSURL(fileURLWithPath: iOSApplicationDirectory as! String).URLByAppendingPathComponent("Documents")
                                            let destinationURL = documentsPath.URLByAppendingPathComponent(fileName)
                                            
                                            do {
                                                try resultFileText.writeToURL(destinationURL, atomically: false, encoding: NSUTF8StringEncoding)
                                            } catch let error as NSError {
                                                print("Cannot write to file -> error: \(error)")
                                            }
                                            
                                            mediaParent = self.appCoreData.getDocumentsDirectoryObject()
                                            
                                            self.appCoreData.addChildFile(mediaParent, url: destinationURL)
                                            
                                        }
                                        else if (UTTypeConformsTo(fileUTI, kUTTypeImage))
                                        {
                                            //For image type
                                            
                                            mediaParent = self.appCoreData.getMediaDirectoryObject(.Image)
                                            
                                            localImagePathUrl = RootController().getLocalImagePathUrl()
                                            
                                            let destinationURL = localImagePathUrl.URLByAppendingPathComponent(fileName)
                                            
                                            var resultImage: UIImage!
                                            
                                            if let resultFileData = NSData(contentsOfURL: resultFile.fileURL) {
                                                resultImage =  UIImage(data: resultFileData)!
                                            }
                                            
                                            // write the image to destination
                                            let imageToWrite = UIImageJPEGRepresentation(resultImage, 1.0)
                                            imageToWrite!.writeToURL(destinationURL, atomically: true)
                                            
                                            self.appCoreData.addChildFile(mediaParent, url: destinationURL)
                                        }
                                            
                                        else if ((UTTypeConformsTo(fileUTI, kUTTypeVideo)) || (UTTypeConformsTo(fileUTI, kUTTypeMovie)))
                                        {
                                            //For video type
                                            mediaParent = self.appCoreData.getMediaDirectoryObject(.Video)

                                            // define where we are going to store it
                                            localImagePathUrl = RootController().getLocalVideoPathUrl()
                                            let destinationURL = localImagePathUrl.URLByAppendingPathComponent(fileName)

                                            // try to move it to destination
                                            do
                                            {
                                                try self.fileManager.moveItemAtURL(resultFile.fileURL , toURL: destinationURL)
                                                self.appCoreData.addChildFile(mediaParent, url: destinationURL)
                                            }
                                            catch let error as NSError
                                            {
                                                NSLog("Error moving file -> %@", error)
                                            }

                                        }
                                        else if (UTTypeConformsTo(fileUTI, kUTTypeAudio))
                                        {
                                            //For audio type
                                            mediaParent = self.appCoreData.getMediaDirectoryObject(.Audio)

                                            // define where we are going to store it
                                            
                                            localImagePathUrl = RootController().getLocalAudioPathUrl()
                                            let destinationURL = localImagePathUrl.URLByAppendingPathComponent(fileName)
                                            
                                            // try to move it to destination
                                            do
                                            {
                                                try self.fileManager.moveItemAtURL(resultFile.fileURL , toURL: destinationURL)
                                                self.appCoreData.addChildFile(mediaParent, url: destinationURL)
                                            }
                                            catch let error as NSError
                                            {
                                                NSLog("Error in moving file -> %@", error)
                                            }
                                        }
                                    }
                                    
                                    let alert = UIAlertController(title: "Success!", message: "Files were successfully downloaded from iCloud.", preferredStyle: .Alert)
                                    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                                    self.presentViewController(alert, animated: true, completion: nil)
                                }
                                else
                                {
                                    let alert = UIAlertController(title: "Error!", message: "No files found.", preferredStyle: .Alert)
                                    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                                    self.presentViewController(alert, animated: true, completion: nil)
                                }
                            }
                            else
                            {
                                print(error)
                                let alert = UIAlertController(title: "Failure!", message: "An Error Occurred.", preferredStyle: .Alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                                self.presentViewController(alert, animated: true, completion: nil)
                            }
                        }
                        
                    }
                    
                    //perform operation
                    privateDatabase.addOperation(operation)
                }
            })
        }
        else
        {
            //No internet connection
            
            dispatch_async(dispatch_get_main_queue(), {
                
                let alert = UIAlertController(title: "Error!", message: "No internet connection.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion:nil)
                
            })
        }
    }
    
    func selectImageFromLibrary()
    {
        self.removeSubviews()
        
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = CTAssetsPickerController()
        
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        
        presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func assetsPickerControllerDidCancel(picker: CTAssetsPickerController!)
    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func assetsPickerController(picker: CTAssetsPickerController!, didFinishPickingAssets assets: [AnyObject]!)
    {
        self.dismissViewControllerAnimated(true, completion: nil)
        print("user selected \(assets.count) media items")
        // get imported directory url and create it if it does not exists
        let importUrl = rootUrl.URLByAppendingPathComponent("Imported Media")
        let photoManager = PHImageManager.defaultManager()
        var importedImage = UIImage()
        do
        {
            
            try fileManager.createDirectoryAtURL(importUrl, withIntermediateDirectories: true, attributes: nil)
            for asset in assets
            {
                // save every asset to that location
                photoManager.requestImageDataForAsset(asset as! PHAsset, options: nil, resultHandler: {
                    (imageData, dataUTI, orientation, info) -> Void in

                    importedImage = UIImage(data: imageData!)!
                    let fileName = "Image-" + self.lib.isoDate() + ".jpg"

                    // give it a destination
                    let localImagePathUrl = RootController().getLocalImagePathUrl()
                    let fileUrl = localImagePathUrl.URLByAppendingPathComponent(fileName)
                    
                    let mediaParent = self.appCoreData.getMediaDirectoryObject(.Image)
                    
                    // write the image to destination
                    let imageToWrite = UIImageJPEGRepresentation(importedImage, 1.0)
                    imageToWrite!.writeToURL(fileUrl, atomically: true)
                    let fileStatus = self.fileManager.fileExistsAtPath(fileUrl.path!)
                    self.appCoreData.addChildFile(mediaParent, url: fileUrl)
                    print("file write status -> \(fileStatus)")
                })
                print(asset)
                // and update coredata
            }
        }
        catch let error as NSError
        {
            NSLog("Error in creating import path -> \(error)")
        }
    }

    // sort presented folder and file list function
    @IBAction func SortListBy(sender: AnyObject)
    {
        print("sortBy called")
        self.removeSubviews()
        
        // ask user how they want to sort their list ... this would apply to both folder and file list
        self.selectSortPattern() { selectedSort in
            print("User selected -> \(selectedSort)")
            self.applySort(selectedSort)
        }
        
    }
    
    func selectSortPattern( sort: (Preferences.DefaultSort) -> ())
    {
        // create alert container
        let alertController = UIAlertController(title:nil, message:nil, preferredStyle: .ActionSheet)
        // define alphabetical
        let alphabetical = UIAlertAction(title: "Name", style: .Default, handler: { (action: UIAlertAction) -> Void in
            sort(.Alphabetical)
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        // define recent
        let recent = UIAlertAction(title: "Recent", style: .Default, handler: { (action: UIAlertAction) -> Void in
            sort(.Recent)
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        // define starred
        let starred = UIAlertAction(title: "Favourites", style: .Default, handler: { (action: UIAlertAction) -> Void in
            sort(.StarredAlphabetical)
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        //define cancel
        let cancel = UIAlertAction(title: "Cancel", style: .Destructive, handler: nil)
        
        // assemble alert optins
        alertController.addAction(alphabetical)
        alertController.addAction(recent)
        alertController.addAction(starred)
        alertController.addAction(cancel)
        
        // present the alert view to the user
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func applySort(sortPattern: Preferences.DefaultSort)
    {
        var selectedSort: [NSSortDescriptor]!
        
        self.isListSortedByFavourite = false
        
        // convert sort pattern to search value for core data fetch
        switch sortPattern
        {
        case .Alphabetical:
            print("Alphabetical sort")
            selectedSort = [NSSortDescriptor(key: "name", ascending: true)]
        case .Recent:
            print("Recent sort")
            selectedSort =  [NSSortDescriptor(key: "modifiedAt", ascending: false)]
        case .StarredAlphabetical: print("Favourties sort")
            let alphaSort = NSSortDescriptor(key: "name", ascending: true)
            let starredSort = NSSortDescriptor(key: "starred", ascending: false)
            selectedSort = [starredSort, alphaSort]
            self.isListSortedByFavourite = true
        default:
            print(" nothing to seee ")
        }
        // sort Directory objects according to sort pattern
        dirArray = NSArray(array: dirArray).sortedArrayUsingDescriptors(selectedSort) as! [Directory]
        // sort File objects according to sort pattern
        fileArray = NSArray(array:fileArray).sortedArrayUsingDescriptors(selectedSort) as! [File]
        
        self.collectionView.reloadData()
        self.tableView.reloadData()
    }
    
    // Filter presented file list function
    @IBAction func FilterListBy(sender: AnyObject)
    {
        print("filterBy called ...")
        self.removeSubviews()
        // Ask user of what kind of filter they would like
        self.selectFilter() { filter in

            print("user selected filter -> \(filter)")
            // apply filter to file list
            self.applyFilter(filter)
        }
        
        
        // reload table data
    }

    // ask user for desired filter
    /* 
     * If the user has persistentFilter on then store that filter in coredata
    */
    func selectFilter(filter: (Preferences.DefaultView) -> ())
    {
        
        // create alert container
        let alertController = UIAlertController(title:nil, message:nil, preferredStyle: .ActionSheet)
        
        // define documents
        let documents = UIAlertAction(title: "Documents", style: .Default, handler: { (action: UIAlertAction) -> Void in
            filter(.Document)
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        // define audio
        let audio = UIAlertAction(title: "Audio", style: .Default, handler: { (action: UIAlertAction) -> Void in
            filter(.Audio)
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        // define video
        let video = UIAlertAction(title: "Video", style: .Default, handler: { (action: UIAlertAction) -> Void in
            filter(.Video)
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        // define photos
        let photos = UIAlertAction(title: "Photos", style: .Default, handler: { (action: UIAlertAction) -> Void in
            filter(.Photo)
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        // define All Files to add filter for showing all files
        let allFiles = UIAlertAction(title: "All Files", style: .Default, handler: { (action: UIAlertAction) -> Void in
            filter(.AllFiles)
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        // define cancel
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        // assemble alert actions
        // added All Files option in filter alertController
        alertController.addAction(allFiles)
        alertController.addAction(documents)
        alertController.addAction(audio)
        alertController.addAction(video)
        alertController.addAction(photos)
        alertController.addAction(cancel)
        
        // present the alert view to the user
        self.presentViewController(alertController, animated: true, completion: nil)

    }
    
    func applyFilter(filter: Preferences.DefaultView)
    {
        let request = NSFetchRequest()
        

        var predicateFormat: String!
        let searchAttribute = "mimetype.group"
        
        // apply specified to fileArray
        switch filter
        {
        case .Document:
            predicateFormat = "((%K MATCHES[cd] %@) OR (%K MATCHES[cd] %@))"
            request.predicate = NSPredicate(format: predicateFormat, searchAttribute, "application", searchAttribute, "text")
        case .Audio:
            predicateFormat = "(%K MATCHES[cd] %@)"
            request.predicate = NSPredicate(format: predicateFormat, searchAttribute, "audio")
        case .Video:
            predicateFormat = "(%K MATCHES[cd] %@)"
            request.predicate = NSPredicate(format: predicateFormat, searchAttribute, "video")
        case .Photo:
            predicateFormat = "(%K MATCHES[cd] %@)"
            request.predicate = NSPredicate(format: predicateFormat, searchAttribute, "image")
        case .AllFiles: print("default filter applied")
        default: NSLog("error: filter not recognized")
        }
        
        let entity = NSEntityDescription.entityForName("File", inManagedObjectContext: context)
        request.entity = entity
               
        do
        {
            self.fileArray = try context.executeFetchRequest(request) as! [File]
            self.tableView.reloadData()
        }
        catch let error as NSError
        {
            NSLog("Error in fetching filter results -> %@", error)
        }
        
    }
    
    // what to do when user selects edit from the popover menu
    @IBAction func editTable()
    {
//        performSegueWithIdentifier("EditView", sender: self)
        self.removeSubviews()
        print("editTable button pressed")
        self.collectionView.allowsMultipleSelection = true
        self.collectionView.reloadData()
        self.tableView.editing = true

        // modify navigation bar
        self.toggleEditNavigationBar()
        // add toolbar
        toggleToolBar(true)
        editingMode = true
        self.tableView.reloadData()
    }

    func toggleEditNavigationBar()
    {
        let barButtons = self.navigationItem.leftBarButtonItems
        self.leftBarButtonItems = barButtons != nil ? barButtons : nil
        self.navigationItem.rightBarButtonItems = nil
        self.navigationItem.leftBarButtonItems = nil
        self.navigationItem.setLeftBarButtonItem(UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelEditing"), animated: true)
    }
    
    func resetNavigationBar()
    {
        print("resetNavigationBar called ")
        let addMenuButton = UIBarButtonItem(image: UIImage(named:"addMenu"), style: .Plain, target: self, action: "showAddMenu:")
        addMenuButton.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -10)
        let menuButton = UIBarButtonItem(image: UIImage(named:"menu"), style: .Plain, target: self, action: "showMenu:")
        menuButton.imageInsets = UIEdgeInsets(top: 0, left: -19, bottom: 0, right: 14)
        let settingMenuButton = UIBarButtonItem(image: UIImage(named:"setting"), style: .Plain, target: self, action: "showSettingsMenu:")
        self.navigationItem.rightBarButtonItems = [menuButton, addMenuButton]
        let barButtons = self.leftBarButtonItems
        print("barButtons -> \(barButtons)")
        self.navigationItem.leftBarButtonItems = barButtons != nil ? [settingMenuButton] : nil
        self.refresh()
    }
    
    func cancelEditing()
    {
        // remove selected Tags
        appCoreData.removeSelectTagForAllChildren()
        
        // remove editing capabilities
        self.collectionView.allowsMultipleSelection = false
        self.tableView.editing = false
        editingMode = false
        self.tableView.reloadData()
        // reset navigation bar
        self.resetNavigationBar()
        // remove toolbar
        toggleToolBar(false)
        // force refresh of view information
        self.refresh()
    }
    
    func toggleToolBar(state:Bool)
    {
        state ? addToolBar() : removeToolBar()
        
        //Setting scrollIndicator's insets to maintain its position
        self.collectionView.scrollIndicatorInsets = UIEdgeInsetsZero
    }
    
    func addToolBar()
    {
        print("addToolBar called ..")
        let copyButton = UIBarButtonItem(image: UIImage(named: "copy"), style: .Plain, target: self, action: "copyItems")
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: "")
        let moveButton = UIBarButtonItem(image: UIImage(named: "move"), style: .Plain, target: self, action: "moveItems")
        let shareButton = UIBarButtonItem(image: UIImage(named: "share"), style: .Plain, target: self, action: "shareItem")
        let deleteButton = UIBarButtonItem(image: UIImage(named:"delete"), style: .Plain, target: self, action: "deleteItems")
        let favouriteButton = UIBarButtonItem(image: UIImage(named: "star"), style: .Plain, target: self, action: "starItems")
        let renameButton = UIBarButtonItem(image: UIImage(named: "rename"), style: .Plain, target: self, action: "renameItem")
        
        
        let buttons = [copyButton, flexSpace, moveButton, flexSpace, shareButton, flexSpace, deleteButton, flexSpace, favouriteButton, flexSpace, renameButton]
        self.setToolbarItems(buttons, animated: true)

        let toolbar = self.navigationController?.toolbar
        
        toolbar?.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(alphaValue)
        toolbar?.tintColor = UIColor.darkGrayColor()
        toolbar?.setBackgroundImage(UIImage(), forToolbarPosition: .Any, barMetrics: .Default)
        toolbar?.setShadowImage(UIImage(), forToolbarPosition: .Any)
        self.navigationController?.toolbarHidden = false
    }
    
    func copyItems()
    {
        self.performSegueWithIdentifier("DisplayCopyDestination", sender: nil)
    }
    func moveItems()
    {
        self.performSegueWithIdentifier("DisplayMoveDestination", sender: nil)
    }
    
    //Show action sheet to select destination for sharing
    func selectShareDestination()
    {
        // create alert container
        let alertController = UIAlertController(title:nil, message:nil, preferredStyle: .ActionSheet)
        
        // define iCloud
        let iCloudMenu = UIAlertAction(title: "iCloud", style: .Default, handler: { (action: UIAlertAction) -> Void in
            
            self.uploadToCloud()
            
        })
        
        // define "More" for sharing between apps
        let moreMenu = UIAlertAction(title: "More", style: .Default, handler: { (action: UIAlertAction) -> Void in
            
            self.shareItem()
            
        })
        
        //define cancel
        let cancel = UIAlertAction(title: "Cancel", style: .Destructive, handler: nil)

        // assemble alert optins
        alertController.addAction(iCloudMenu)
        alertController.addAction(moreMenu)
        alertController.addAction(cancel)
        
        // present the alert view to the user
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func shareItem()
    {
        // N.B. UIActivityViewController only works with one selected item at a time
        // get url for selected object
        let selectedUrl = appCoreData.getUrlsForSelectedObjects()
        print("selectedUrl.count -> \(selectedUrl.count)")
        // TODO: Look into 2° activities like copy, print, etc.
        let activityViewController = UIActivityViewController(activityItems: selectedUrl, applicationActivities: nil)
        self.navigationController?.presentViewController(activityViewController, animated: true) {}
        
        //remove selection from all selected objects after sharing
        appCoreData.removeSelectTagForAllChildren()
        
    }
    
    func deleteItems()
    {
        print("deleteItems clicked")
        
        let dirsToBeDeleted = appCoreData.fetchSelectedObjects(objects: .Directory) as! [Directory]
        for dir in dirsToBeDeleted
        {
            print("directory has -> \(dir.hasDirectories!.count) Dirs and -> \(dir.hasFiles!.count) Files")
            if dir.hasDirectories!.count > 0 || dir.hasFiles!.count > 0
            {
                let alert = UIAlertController(title:"Warning", message: "", preferredStyle: .Alert)
                alert.message = "The folder \(dir.name!) contains files and/or directories. Please erase those items first!"
                alert.addAction(UIAlertAction(title: "Cancel", style: .Destructive, handler: { (action: UIAlertAction) -> Void in
                    self.dismissViewControllerAnimated(true, completion: nil)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
            }
            else
            {
                do
                {
                    try fileManager.removeItemAtURL(dir.url!)
                    appCoreData.deleteChildDir(dir)
                }
                catch let error as NSError
                {
                    NSLog("Error in deleting directory object -> %@", error)
                }
            }
        }
        
        let filesToBeDeleted = appCoreData.fetchSelectedObjects(objects: .File) as! [File]
        for file in filesToBeDeleted
        {
            do
            {
                try fileManager.removeItemAtURL(file.url!)
                appCoreData.deleteChildFile(file)
            }
            catch let error as NSError
            {
                NSLog("Error in deleting directory object -> %@", error)
            }
        }
        self.cancelEditing()
    }
    
    func starItems()
    {
        print ("starItems clicked")
        let selectedObjects = self.appCoreData.getAllSelectedObjects()
        if selectedObjects!.count > 0 && selectedObjects!.count > 1
        {
            print("we have more than one object selected!!")
            // if > 1 warn the user that you can only rename on object at a time
            let alert = UIAlertController(title:"Warning", message: "", preferredStyle: .Alert)
            alert.message = "This function can only be used to rename one item at a time. Please select one item and try again."
            alert.addAction(UIAlertAction(title: "Cancel", style: .Destructive, handler: { (action: UIAlertAction) -> Void in
                self.dismissViewControllerAnimated(true, completion: nil)
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else
        {
            appCoreData.starAllSelectedObjects()
            self.cancelEditing()
        }
    }
    
    func renameItem()
    {
        print("renameItem called")
        // figure out how many objects are selected
        let selectedObjects = self.appCoreData.getAllSelectedObjects()
        if selectedObjects!.count > 0 && selectedObjects!.count > 1
        {
            print("we have more than one object selected!!")
            // if > 1 warn the user that you can only rename on object at a time
            let alert = UIAlertController(title:"Warning", message: "", preferredStyle: .Alert)
            alert.message = "This function can only be used to rename one item at a time. Please select one item and try again."
            alert.addAction(UIAlertAction(title: "Cancel", style: .Destructive, handler: { (action: UIAlertAction) -> Void in
                self.dismissViewControllerAnimated(true, completion: nil)
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else
        {
        // otherwise
        // ask user for new name
            print("ok user understands ...")
            self.getName(selectedObjects![0].name, type: .Rename) { newName in
                if !newName.isEmpty
                {

                    var url: NSURL!
                    // figure out what kind of file object we have
                    let dirs = self.appCoreData.fetchSelectedObjects(objects: .Directory) as! [Directory]
                    let files = self.appCoreData.fetchSelectedObjects(objects: .File) as! [File]
                    
                    if dirs.count > 0
                    {
                        print("we're dealing with a directory")
                        url = dirs[0].url
                        let newUrl = url.URLByDeletingLastPathComponent?.URLByAppendingPathComponent(newName)
                        do
                        {
                            try self.fileManager.moveItemAtURL(url, toURL: newUrl!)
                            // rename appropriate object
                            self.appCoreData.renameChildDir(dirs[0], newName: newName)
                        }
                        catch let error as NSError
                        {
                            NSLog("Error in renaming directory -> \(error)")
                        }

                    }
                    
                    if files.count > 0
                    {
                        print("we're dealing with a file")
                        url = files[0].url
                        let newUrl = url.URLByDeletingLastPathComponent?.URLByAppendingPathComponent(newName)
                        do
                        {
                            try self.fileManager.moveItemAtURL(url, toURL: newUrl!)
                            // rename appropriate object
                            self.appCoreData.renameChildFile(files[0], newName: newName)
                        }
                        catch let error as NSError
                        {
                            NSLog("Error in renaming file -> \(error)")
                        }
                    }
                 }
                self.cancelEditing()
            }

        }

    }
    
    func removeToolBar()
    {
        print("removeToolBar called ..")
        self.navigationController?.toolbarHidden = true
    }
    
    @IBAction func addFolder()
    {
        
        print("Add Folder to the following url -> \(currentDirUrl)")
        self.removeSubviews()
        
        self.getName("New Folder", type: .Folder) { result in
            print("alert result -> \(result)")
            if !result.isEmpty
            {
                let newDirUrl = self.currentDirUrl?.URLByAppendingPathComponent(result, isDirectory: true)
                
                do
                {
                    try NSFileManager.defaultManager().createDirectoryAtURL(newDirUrl!, withIntermediateDirectories: true, attributes: nil)
                    
                    // add new directory to core data
                    self.appCoreData.addChildDir(self.parent, url: newDirUrl!)
                    self.appCoreData.saveContext()
                    self.dirArray.append(self.appCoreData.fetchObjectAtUrl(newDirUrl!) as! Directory)
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
        
    }
    
    
    // function to create an alert
    // valid types: File, Folder, Rename
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
    
    func activateMenuForSelectedCollectionViewCell(gesture:UILongPressGestureRecognizer)
    {
        if (gesture.state == UIGestureRecognizerState.Began)
        {
            let indexPath = self.collectionView.indexPathForItemAtPoint(gesture.locationInView(self.collectionView))
//            let collectionViewCell = self.collectionView.cellForItemAtIndexPath(indexPath!)
            let object = dirArray[indexPath!.row]
            menuForSelectedCell(object, objectType: .Directory)
        }
    }
    
    // choices presented for collection view cell selection
    // implicit assumtion is that this is only called by cell referencing a Directory
    func menuForSelectedCell(object:AnyObject, objectType: AppCoreData.ObjectType)
    {
        var url: NSURL?
        var child: AnyObject?
        switch objectType
        {
        case .Directory: child = object as! Directory
        case .File: child = object as! File
        }
        
        url = child!.url
        
        let alertController = UIAlertController(title:nil, message:nil, preferredStyle: .ActionSheet)
        
        let share = UIAlertAction(title:"Share", style: .Default, handler: { (alert:UIAlertAction) -> Void in
            
            // TODO: Look into 2° activities like copy, print, etc.
            let activityViewController = UIActivityViewController(activityItems: [url!], applicationActivities: nil)
            self.navigationController?.presentViewController(activityViewController, animated: true, completion:nil)
        })
        
        let rename = UIAlertAction(title: "Rename", style: .Default, handler: {
            (alert:UIAlertAction) -> Void in
            self.getName(child!.name, type: .Rename) { result in
                print("alert result -> \(result)")
                
                let newUrl = url!.URLByDeletingLastPathComponent?.URLByAppendingPathComponent(result)
                
                do
                {
                   try self.fileManager.moveItemAtURL(url!, toURL: newUrl!)
                    // TODO: add hooks for protocol f_rename
                    // device.
                    // update core data
                    switch objectType
                    {
                    case .Directory:
                        self.appCoreData.renameChildDir(child as! Directory, newName: result)

                    case .File:
                        self.appCoreData.renameChildFile(child as! File, newName: result)
                    }

                }
                catch let error as NSError
                {
                    print("Cannot rename object -> error: \(error)")
                }
                catch
                {
                    fatalError()
                }
                
                self.dismissViewControllerAnimated(true, completion: { () -> Void in
                    
                })
                self.refresh()
            }
        })
        let move = UIAlertAction(title: "Move", style: .Default, handler: { (aler: UIAlertAction) -> Void in
            self.performSegueWithIdentifier("DisplayDestination", sender: child)
        })
        let delete = UIAlertAction(title: "Delete", style: .Destructive, handler: {
            (alert:UIAlertAction) -> Void in
            print("delete button selected")
            
            // this mode is only available for directories
            do
            {
                try self.fileManager.removeItemAtURL(url!)
                self.appCoreData.deleteChildDir(child as! Directory)
                self.refresh()
            }
            catch let error as NSError
            {
                NSLog("error in delete action -> %@", error)
            }
        })
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        alertController.addAction(share)
        alertController.addAction(rename)
        alertController.addAction(move)
        if (objectType == .Directory)
        {
           alertController.addAction(delete)
        }
        alertController.addAction(cancel)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: segue definitions

    // In the event the user chooses a text viewer, we need to prep the data
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool
    {
        print("editing states")
        print("collectionView -> \(self.collectionView.allowsMultipleSelection)")
        print("tableView -> \(self.tableView.editing)")
//        return (self.collectionView.allowsMultipleSelection) ? false : true
        return self.editingMode.boolValue ? false : true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        print("segue -> \(segue.identifier)")
        self.removeSubviews()
        switch segue.identifier!
        {
            // directory traversing
        case "EnterDirectory":
            let indexPath = self.collectionView.indexPathsForSelectedItems()![0]
            let selectedUrl = dirArray[indexPath.row].url!
            if let childView = segue.destinationViewController as? PeripheralViewController
            {
                // update date
                let object = appCoreData.fetchObject(dirArray[indexPath.row], objectType: .Directory) as! Directory
                object.accessedAt = NSDate()
                appCoreData.saveContext()
                
                childView.currentDirUrl = selectedUrl
                childView.title = selectedUrl.lastPathComponent
                childView.navigationItem.setLeftBarButtonItem(nil, animated: true)
                self.collectionView.deselectItemAtIndexPath(indexPath, animated: false)
            }
            
            // move/copy transaction
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

            // display audio/video files
        case "ShowAudioMedia", "ShowVideoMedia":
            let indexPath = sender as! NSIndexPath
            if let AVView = segue.destinationViewController as? AVMediaController
            {
                // update date
                let object = appCoreData.fetchObject(fileArray[indexPath.row], objectType: .File) as! File
                object.accessedAt = NSDate()
                appCoreData.saveContext()
             
                AVView.fileArray = fileArray
                AVView.index = indexPath.row
//                let url = fileArray[indexPath.row].url!
//                AVView.player = AVPlayer(URL: url)
            }

        case "ShowPreferences":
            segue.destinationViewController as! SystemPreferencesController
            
        case "ShowSystemInfo":
            segue.destinationViewController as! AccessoryDetailViewController
            
        // display image
        case "ShowImage":
            let indexPath = sender as! NSIndexPath
            if let imageView = segue.destinationViewController as? ViewImageController
            {
                // update date
                let object = appCoreData.fetchObject(fileArray[indexPath.row], objectType: .File) as! File
                object.accessedAt = NSDate()
                appCoreData.saveContext()
                
                imageView.fileUrl = fileArray[indexPath.row].url!
                imageView.fileArray = fileArray
                imageView.index = indexPath.row
                imageView.title = imageView.fileUrl.lastPathComponent
            }

            // display all other files using uiwebview
        case "ShowContentsOfFile":
            let indexPath = sender as! NSIndexPath
            if let viewFile = segue.destinationViewController as? FileViewController
            {
                // update date
                let object = appCoreData.fetchObject(fileArray[indexPath.row], objectType: .File) as! File
                object.accessedAt = NSDate()
                appCoreData.saveContext()
                viewFile.fileArray = fileArray
                viewFile.index = indexPath.row
//                viewFile.object = fileArray[indexPath.row] 
                viewFile.fileUrl = fileArray[indexPath.row].url!
                viewFile.title = viewFile.fileUrl!.lastPathComponent
            }
        case "DisplaySearchView":
            segue.destinationViewController as! SearchVC
        default:
            NSLog("No segue identifier found")
        }
        
        
    }
    
    // action when canceling from MoveCopyViewController
    @IBAction func returnFromMoveCopyView(segue: UIStoryboardSegue)
    {
        self.navigationController?.toolbarHidden = true
        self.cancelEditing()
    }
    
    @IBAction func returnFromFullFileView(segue: UIStoryboardSegue)
    {
        print("returning to peripheral view with url -> \(currentDirUrl)")
    }
    
    
    // MARK: Photo/Video Capture

    func captureMedia()
    {
        
        if UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) != nil
        {
            imagePicker = UIImagePickerController()
            imagePicker.allowsEditing = false
            imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
            imagePicker.cameraCaptureMode = .Photo
            
            let imageType:String = kUTTypeImage as String
            let movieType:String = kUTTypeMovie as String
            imagePicker.mediaTypes = [imageType,movieType]
            
            //Disable default camera controls to add custom controls
            imagePicker.showsCameraControls = false
            
            //Display camera in full screen mode
            let translate:CGAffineTransform = CGAffineTransformMakeTranslation(0.0, 71.0) //This slots the preview exactly in the middle of the screen by moving it down 71 points
            imagePicker.cameraViewTransform = translate;
            
            let scale:CGAffineTransform = CGAffineTransformScale(translate, 1.333333, 1.333333)
            imagePicker.cameraViewTransform = scale
            
            
            
            //Adding CustomOverlayView to picker's camera overlayView
            let customViewController = CustomOverlayViewController(
                nibName:"CustomOverlayViewController",
                bundle: nil
            )
            let customView:CustomOverlayView = customViewController.view as! CustomOverlayView
            customView.frame = self.imagePicker.view.frame
            customView.delegate = self
            
            presentViewController(imagePicker,
                animated: true,
                completion: {
                    self.imagePicker.cameraOverlayView = customView
                }
            )
        }
        else
        {
            self.noCamera()
        }
    }
    
    func noCamera()
    {
        let alertVC = UIAlertController(
            title: "No Camera",
            message: "This device has no camera",
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
    
    // MARK: CustomOverlayView delegate Methods
    
    //Called to dismiss picker when Done Button is tapped
    func didCancel(overlayView:CustomOverlayView)
    {
        imagePicker.dismissViewControllerAnimated(true,
            completion: nil)
    }
    
    //Called to take picture when Capture button is called
    func didShoot(overlayView:CustomOverlayView)
    {
        imagePicker.delegate = self
        
        if(photoCaptureMode.boolValue)
        {
            imagePicker.takePicture()
        }
        else
        {
            
            if(isRecording.boolValue)
            {
                imagePicker.stopVideoCapture()
                isRecording = false
                
                let btnImage : UIImage? = UIImage(named:"recordVideo")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
                overlayView.cameraActionButton.setImage(btnImage, forState: UIControlState.Normal)
            }
            else
            {
                imagePicker.startVideoCapture()
                isRecording = true
                
                let btnImage : UIImage? = UIImage(named:"stopRecording")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
                overlayView.cameraActionButton.setImage(btnImage, forState: UIControlState.Normal)
            }
        }
    }
    
    //Called to switch between front and rear camera
    func changeCamera(overlayView:CustomOverlayView)
    {
        if(imagePicker.cameraDevice == .Rear)
        {
          self.imagePicker.cameraDevice = .Front
        }
        else
        {
            self.imagePicker.cameraDevice = .Rear
        }
    }
    
    //Called to switch between video recording and photo capture
    func changeCaptureMode(overlayView:CustomOverlayView)
    {
        if(photoCaptureMode.boolValue)
        {
            //Video Recording mode
            photoCaptureMode = false
            imagePicker.cameraCaptureMode = .Video
            
            let btnImage : UIImage? = UIImage(named:"recordVideo")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
            overlayView.cameraActionButton.setImage(btnImage, forState: UIControlState.Normal)

        }
        else
        {
            //Photo Capture Mode
            photoCaptureMode = true
            imagePicker.cameraCaptureMode = .Photo
            
            //if recording mode was on, stop recording
            imagePicker.stopVideoCapture()
            isRecording = false
            
            let btnImage : UIImage? = UIImage(named:"Capture")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
            overlayView.cameraActionButton.setImage(btnImage, forState: UIControlState.Normal)
        }
    }
    
    //MARK: Image Picker Controller Delegates
    
    // what to do when the photo capture ends
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        // check if we are saving a movie
        if info[UIImagePickerControllerMediaType] as! NSString == "public.movie"
        {
            // case: saving a movie
            // grab the url of where the movie is currently stored
            let videoUrl  = info[UIImagePickerControllerMediaURL]
            // give it a name
            let fileName = "MOV-" + lib.isoDate() + ".MOV"
            // define where we are going to store it
            let localVideoPathUrl = RootController().getLocalVideoPathUrl()
            let fileUrl = localVideoPathUrl.URLByAppendingPathComponent(fileName)
            
            // get parent Directory object
            let mediaParent = appCoreData.getMediaDirectoryObject(.Video)
            // try to move it to destination
            do
            {
                try fileManager.moveItemAtURL(videoUrl as! NSURL, toURL: fileUrl)
                appCoreData.addChildFile(mediaParent, url: fileUrl)
                print("successful file move")
            }
            catch let error as NSError
            {
                print("error moving video -> \(error)")
            }
        }
        else
        {
            // case: saving an image
            // grab the image itself
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            // give it a name
            let fileName = "Image-" + lib.isoDate() + ".jpg"
            print("filename to write to -> \(fileName)")
            // give it a destination
            let localImagePathUrl = RootController().getLocalImagePathUrl()
            let fileUrl = localImagePathUrl.URLByAppendingPathComponent(fileName)
            let mediaParent = appCoreData.getMediaDirectoryObject(.Image)
            // write the image to destination
            let imageToWrite = UIImageJPEGRepresentation(image, 1.0)
            imageToWrite!.writeToURL(fileUrl, atomically: true)
            let fileStatus = fileManager.fileExistsAtPath(fileUrl.path!)
            appCoreData.addChildFile(mediaParent, url: fileUrl)
            print("file write status -> \(fileStatus)")
//            NSLog("saving picture to peripheral")
//            let xtr = XTR()
//            xtr.f_write(UIImageJPEGRepresentation(image, 1.0)!, fileName: fileName, type: .Image)
        }
    }
    
    // what to do when the photo capture is cancelled
    func imagePickerControllerDidCancel(picker: UIImagePickerController)
    {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // this method will disable swipe depending on morePressed value
    func swipeableTableViewCell(cell: SWTableViewCell!, canSwipeToState state: SWCellState) -> Bool {
        
        if morePressed == true
        {
            switch(state)
            {
            case SWCellState.CellStateLeft:
                return false
                
            case SWCellState.CellStateRight:
                return false

            default:
                return true
            }
        }
        return true
    }
}
