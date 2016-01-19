
//
//  SearchVC.swift
//  xtraSD
//
//  Created by Successive Software on 1/19/16.
//  Copyright © 2016 iXTRA Technologies. All rights reserved.
//

import UIKit
import CoreData
import AVKit
import AVFoundation


class FileObjectInfo
{
    var name: String!
    var url: NSURL!
}


class SearchVC: UIViewController, UITableViewDataSource, UITableViewDelegate, SWTableViewCellDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, AVAudioPlayerDelegate, UIGestureRecognizerDelegate,UISearchBarDelegate
{
    
// Pragma:  Class Variables
    
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    @IBOutlet weak var searchBar : UISearchBar!;
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    
    let searchRequest = NSFetchRequest()
    var filteredData: [AnyObject] = []
    var fileDataArray: [AnyObject] = [];
    var folderDataArray: [AnyObject] = [];
    var dirArray:[Directory] = []
    var fileArray: [File] = []
    let appCoreDate = AppCoreData()
    let lib = Library()
    let folderCellIdentifier = "folderCell";
    let cellHeightScaler: CGFloat = 0.45
    let cellSeparatorHeight: CGFloat = 1.0
    var noFolderFoundNotice: UIView!;
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.allowsMultipleSelection = false;
        self.automaticallyAdjustsScrollViewInsets = false;
        self.edgesForExtendedLayout = UIRectEdge.None;
        
        let label = "Search"
        self.navigationItem.title = label.uppercaseString
        // hide back button
        self.navigationItem.setHidesBackButton(true, animated: false)
        // setup Done button on right side
        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "segueBack")
        barButtonItem.tintColor = UIColor(red: 74/255, green: 146/255, blue: 226/255, alpha: 1.0)
        self.navigationItem.setRightBarButtonItem(barButtonItem, animated: true)
    }
    func segueBack()
    {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true);
        self.navigationController?.toolbarHidden  = true;
        
        self.searchBar.delegate = self;
        
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    // MARK: search functions
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar)
    {
        self.searchBar.showsCancelButton = false;
        searchBar.resignFirstResponder();
    }
    
    
    func searchBar(searchBar: UISearchBar, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool
    {
        self.searchBar.showsCancelButton = true;
        self.searchForText(text);
        self.tableView.reloadData();
        
        return true;
    }
    
    func searchForText(searchString:String)
    {
        NSLog("search text %@", searchString);
        let predicateFormat = "%K CONTAINS[cd] %@"
        let searchAttribute = "name"
        
        let predicate = NSPredicate(format: predicateFormat, searchAttribute, searchString)
        self.searchRequest.predicate = predicate
        
        let dirEntity = NSEntityDescription.entityForName("Directory", inManagedObjectContext: context)
        self.searchRequest.entity = dirEntity
        
        
        do
        {
            self.filteredData = try context.executeFetchRequest(searchRequest);
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
        
        
        for var i = 0; i < self.filteredData.count; i++
        {
            let data = filteredData[i];
            if lib.isUrlDirectory(data.url()) == "YES"
            {
                NSLog("It's a Directory ");
                self.folderDataArray.append(data);
            }
            else
            {
                NSLog("It's a File");
                self.fileDataArray.append(data);
            }
        }

        self.tableView.reloadData();
        self.collectionView.reloadData();
        
    }

    
    
    
    
    
    
    
    
    
    
    
    
    //MARK: TableView Definitions
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.fileDataArray.count;//(self.fileDataArray.count > 0) ? self.fileDataArray.count : 0;
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        
         NSLog("Here i am setting CELLES");
        
        let builtCell: SWTableViewCell!
        let normalFileCellIdentifier = "fileCell"
        let imageFileCellIdentifier = "imageCell"
        let videoFileCellIdentifier = "videoCell"
        let audioFileCellIdentifier = "audioCell"
        
        let object : File = self.fileDataArray[indexPath.row] as! File
        let url = object.url;
        let mimeClass = lib.getMimeClass(url!);

        switch mimeClass
        {
        case "image":
            let dequeued  = self.tableView.dequeueReusableCellWithIdentifier(imageFileCellIdentifier)
            let cell = dequeued as! ImageTableViewCell
            
            cell.previewImage.image = UIImage(contentsOfFile: url!.path!)
            cell.previewImage.frame = cell.contentView.bounds
            cell.previewImage.contentMode = .ScaleAspectFill
            cell.previewImage.sizeToFit()
            
            cell.activateTableViewCellSelection(false)
            
            //Show if object is Favourite or not.
            if(object.isStarred.boolValue)
            {
                cell.starImage.hidden = false
            }
            else
            {
                cell.starImage.hidden = true
            }
            
            builtCell = cell
        
        case "video":
            let dequeued  = self.tableView.dequeueReusableCellWithIdentifier(videoFileCellIdentifier)
            let cell = dequeued as! VideoTableViewCell
            cell.movieController.player = AVPlayer(URL: url!)
            
            cell.movieController.view.frame = cell.contentView.bounds
            cell.movieController.view.sizeToFit()
            cell.movieController.videoGravity  = AVLayerVideoGravityResizeAspectFill
            cell.movieController.showsPlaybackControls = false
            //            cell.togglePlayStopButtons()
            cell.contentView.insertSubview(cell.movieController.view, atIndex: 0)
            
            // Added check to allow userInteration if selection mode is disabled
            cell.playButton.userInteractionEnabled = true
            
            //Show if object is Favourite or not.
            if(object.isStarred.boolValue)
            {
                cell.starImage.hidden = false
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
                try cell.audioPlayer = AVAudioPlayer(contentsOfURL: url!)
                cell.audioPlayer?.delegate = self
                cell.audioPlayer?.prepareToPlay()
                cell.bringSubviewToFront(cell.play)
                cell.play.hidden = false
                cell.stop.hidden = true
                cell.fileName.text = url!.lastPathComponent
                cell.fileObject = fileArray[indexPath.row]
                
                cell.activateTableViewCellSelection(false);
            }
            catch
            {
                print("audioplayer encountered an error -> \(error)")
            }

            if(object.isStarred.boolValue)
            {
                cell.starImage.hidden = false
            }
            else
            {
                cell.starImage.hidden = true
            }
            
            builtCell = cell
        default:
            let dequeued  = self.tableView.dequeueReusableCellWithIdentifier(normalFileCellIdentifier)
            let cell = dequeued as! FileTableViewCell
            cell.fileContentView.loadRequest(NSURLRequest(URL: url!))
            cell.fileContentView.frame = self.tableView.rectForRowAtIndexPath(indexPath)
            cell.fileContentView.autoresizingMask = .None
            
            cell.activateTableViewCellSelection(false)
            
            //Check if the default sort is set
            if(object.isStarred.boolValue)
            {
                cell.starImage.hidden = false
            }
            else
            {
                cell.starImage.hidden = true
            }
            
            builtCell = cell
        }
        
        // add left/right swipe functionality
        //builtCell.leftUtilityButtons = self.leftButtons() as [AnyObject]
        //builtCell.rightUtilityButtons = self.rightButtons() as [AnyObject]
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
        
        let object : File = fileDataArray[indexPath.row] as! File
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
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        
    }
    
    
    
    
    
    // MARK: Colleciton view
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int
    {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return (folderDataArray.count > 0) ? folderDataArray.count : 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(folderCellIdentifier, forIndexPath: indexPath) as! FolderCollectionViewCell
        
        
        // when we have directories to show create the cells, otherwise display a notification
        if folderDataArray.count > 0
        {
            // make sure that the notification is removed
            self.noFolderFoundNotice.removeFromSuperview();
            
            let object : Directory = folderDataArray[indexPath.row] as! Directory;
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
            // we have nothing to show, therefore return an empty cell
            cell.icon.image = nil
            cell.folderName.text = ""
            cell.activateCellSelection(false)
            self.noFolderFoundNotice = UIView();
            self.noFolderFoundNotice.frame = CGRectMake(0,0, self.view.bounds.size.width, 110);
            
            let lbl = UILabel(frame: self.noFolderFoundNotice.bounds);
            lbl.textAlignment = NSTextAlignment.Center;
            lbl.numberOfLines = 4;
            lbl.text = "There are no folder to show";
            self.noFolderFoundNotice.addSubview(lbl);
            self.collectionView.addSubview(self.noFolderFoundNotice)
        }
        
        return cell
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        
        
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath)
    {
        
    }

}
