//
//  CameraSyncSelectFolderViewController.swift
//  xtraSD
//
//  Created by optimusmac-12 on 24/12/15.
//  Copyright © 2015 iXTRA Technologies. All rights reserved.
//

import UIKit
import AssetsLibrary

class CameraSyncSelectFolderViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var assetsLibrary = ALAssetsLibrary()
    var groups = NSMutableArray()
    var selectedAlbums = NSMutableArray()
    var fetchedSelectedAlbums = NSMutableArray()
    let appCoreData = AppCoreData()
    let fileManager = NSFileManager.defaultManager()
    var userAlbums = PHFetchResult()
    var result = PHFetchResult()
    var resultVideo = PHFetchResult()   // to save video assets being fetched
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Select folders to Sync"
        
        let btnStartSync = UIBarButtonItem(image: UIImage(named:"sync"), style: .Plain, target: self, action: "startSync")
        
        self.navigationItem.setRightBarButtonItem(btnStartSync, animated: true)
        
        groups.removeAllObjects()
        
        //Fetching list of all albums present in user's device
        self.assetsLibrary.enumerateGroupsWithTypes((ALAssetsGroupAll),
            usingBlock: {
                (group: ALAssetsGroup!, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                if group != nil {
                    
                    group.enumerateAssetsUsingBlock({
                        (asset: ALAsset!, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                        
                        if asset != nil
                        {
                            print(asset)
                        }
                    })
                    self.groups.addObject(group)
                }
                else{
                    self.tableView.reloadData()
                }
            },
            failureBlock: {
                (myerror: NSError!) -> Void in
                print("error occurred: \(myerror.localizedDescription)")
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.groups.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = self.tableView.cellForRowAtIndexPath(indexPath)! as UITableViewCell
        if cell.accessoryType == UITableViewCellAccessoryType.Checkmark{
            cell.accessoryType = UITableViewCellAccessoryType.None
            self.selectedAlbums.removeObject((cell.textLabel?.text)!)
        }
        else{
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            self.selectedAlbums.addObject((cell.textLabel?.text)!)
        }
    }
        
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCellWithIdentifier("resultCell")! as UITableViewCell
        
        let groupForCell = self.groups[indexPath.row] as! ALAssetsGroup
        let posterImage = UIImage(CGImage: groupForCell.posterImage().takeUnretainedValue())
        cell.textLabel!.text = (groupForCell.valueForProperty(ALAssetsGroupPropertyName) as! String)
        cell.imageView?.image = posterImage
        if selectedAlbums.containsObject((cell.textLabel?.text)!)
        {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        else{
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        return cell
    }
    
    func startSync(){           // method called when user presses sync button after selecting albums to be synced
        
        // fetch the albums which user has selected for syncing
        if NSUserDefaults.standardUserDefaults().objectForKey("selectedAlbums") != nil
        {
            fetchedSelectedAlbums = NSUserDefaults.standardUserDefaults().objectForKey("selectedAlbums") as! NSMutableArray
        }
        
        for album in fetchedSelectedAlbums
        {
            selectedAlbums.addObject(album)
        }
        
        if selectedAlbums.count > 0{
            
            if self.groups.count != 0   // self.groups will be nill when background syncing is being performed. So show alert msg only when user is setting up sync feature (not during background syncing)
            {
                showAlertView("Your Album(s) will be synced", title: "Syncing", buttonAction: true)
            }
            print("Sync Start")

            for var i = 0; i < selectedAlbums.count ; i++
            {
                let userAlbumOptions = PHFetchOptions()
                userAlbumOptions.predicate = NSPredicate(format: "title = %@", selectedAlbums.objectAtIndex(i) as! String)
                
                if selectedAlbums.objectAtIndex(i) as! String == "Camera Roll"  // Check if user has selected Camera Roll for syncing otherwise goto else block
                {
                    self.result = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: nil)
                    self.resultVideo = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Video, options: nil)   // fetching all the video assets.
                }
                else
                {
                    userAlbums = PHAssetCollection.fetchAssetCollectionsWithType(.Album , subtype: .AlbumRegular, options: userAlbumOptions)
                    userAlbums.enumerateObjectsUsingBlock({(AnyObject, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                    
                        // creating two option variables one for image assets and other for video assets, to be used while fetcing assets from device
                        let optionImage = PHFetchOptions()
                        optionImage.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.Image.rawValue)
                        let optionVideo = PHFetchOptions()
                        optionVideo.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.Video.rawValue)
                    let collection = AnyObject as! PHAssetCollection
                    self.result = PHAsset.fetchAssetsInAssetCollection(collection, options: optionImage)   // fetching all the image assets from selected albums in  result
                        
                    self.resultVideo = PHAsset.fetchAssetsInAssetCollection(collection, options: optionVideo)   //// fetching all the video assets from selected albums in  result
                        
                    print(self.result.count)
                    print(self.resultVideo.count)
                })
                }
                if (NSUserDefaults.standardUserDefaults().objectForKey("syncChoice")?.integerValue)! == 1   // if user has selected "move" option then delete assets from device
                {
                    deleteAssetsFromDevice(self.result)
                    deleteAssetsFromDevice(self.resultVideo)
                }
                
                copyAssets(self.result, videoAssetToAdd: self.resultVideo)    // copying of assets will be done in both in "move" and "copy"
            }
        }
        else{
            showAlertView("Please select atleast an Album",title: "Message",buttonAction: false)
        }
        NSUserDefaults.standardUserDefaults().setObject(selectedAlbums, forKey: "selectedAlbums")
    }
    
    func copyAssets(imageAssetToAdd: PHFetchResult,videoAssetToAdd: PHFetchResult){     // method to copy all the assets from selected albums
        
        let photoManager = PHImageManager.defaultManager()
        var importedImage = UIImage()

        for var j = 0 ; j < imageAssetToAdd.count ; j++
        {
            let asset = imageAssetToAdd.objectAtIndex(j)
            
            // save every asset to image folder location
            photoManager.requestImageDataForAsset(asset as! PHAsset , options: nil, resultHandler: {
                
                (imageData, dataUTI, orientation, info) -> Void in
                
                importedImage = UIImage(data: imageData!)!
                
                let assetInfo = info! as NSDictionary
                print(assetInfo.objectForKey("PHImageFileURLKey"))
                let path: NSURL = assetInfo.objectForKey("PHImageFileURLKey") as! NSURL
                print(path.lastPathComponent)
                
                let fileName = path.lastPathComponent! as String
                
                // give it a destination
                let localImagePathUrl = RootController().getLocalImagePathUrl()
                let fileUrl = localImagePathUrl.URLByAppendingPathComponent(fileName)
                
                let fileStatus = self.fileManager.fileExistsAtPath(fileUrl.path!)
                
                if fileStatus == false
                {
                    let mediaParent = self.appCoreData.getMediaDirectoryObject(.Image)
                
                    // write the image to destination
                    let imageToWrite = UIImageJPEGRepresentation(importedImage, 1.0)
                    imageToWrite!.writeToURL(fileUrl, atomically: true)
                    let fileStatus = self.fileManager.fileExistsAtPath(fileUrl.path!)
                    self.appCoreData.addChildFile(mediaParent, url: fileUrl)
                    print("file write status -> \(fileStatus)")
                }
            })
        }
        
        // For saving video assets fetched in resultVideo
        
        for var j = 0 ; j < videoAssetToAdd.count ; j++
        {
            let asset = videoAssetToAdd.objectAtIndex(j)
            
            // save every asset to video folder location
            let options = PHVideoRequestOptions()
            options.deliveryMode = .Automatic
            options.networkAccessAllowed = true
            options.version = .Current

            PHCachingImageManager().requestAVAssetForVideo(asset as! PHAsset, options: options, resultHandler: {(asset: AVAsset?,
                audioMix: AVAudioMix?,
                info: [NSObject: AnyObject]?) in
                let assetInfo = asset as! AVURLAsset
                let path: NSURL = assetInfo.URL
                print(path.lastPathComponent)
                
                let fileName = path.lastPathComponent! as String
                
                // give it a destination
                let localVideoPathUrl = RootController().getLocalVideoPathUrl()
                let fileUrl = localVideoPathUrl.URLByAppendingPathComponent(fileName)
                
                let fileStatus = self.fileManager.fileExistsAtPath(fileUrl.path!)
                
                if fileStatus == false
                {
                    let mediaParent = self.appCoreData.getMediaDirectoryObject(.Video)
                    
                    // write the image to destination
                    let videoAsset = asset as? AVURLAsset
                    let videoToWrite = NSData(contentsOfURL: videoAsset!.URL)
                    videoToWrite!.writeToURL(fileUrl, atomically: true)
                    let fileStatus = self.fileManager.fileExistsAtPath(fileUrl.path!)
                    self.appCoreData.addChildFile(mediaParent, url: fileUrl)
                    print("file write status -> \(fileStatus)")
                }
            })
        }
    }

    func deleteAssetsFromDevice(assetsTodelete: PHFetchResult){ // will delete all the assets from the selected albums from device
        
        print("moved from photo library")
        PHPhotoLibrary.sharedPhotoLibrary().performChanges( {
                PHAssetChangeRequest.deleteAssets(assetsTodelete)},
                completionHandler: {
                    success, error in
                    NSLog("Finished deleting asset. %@", (success ? "Success" : error!))
            })
        }
    
    func showAlertView(msg: String, title: String, buttonAction: Bool){
        
        let alertVC = UIAlertController(
            title: title,
            message: msg,
            preferredStyle: .Alert
        )
        let okAction = UIAlertAction(
            title: "OK",
            style: .Default,
            handler: { action in
                if buttonAction == true{
                    self.navigationController?.popViewControllerAnimated(true)
                }
            }
        )
        alertVC.addAction(okAction)
        presentViewController(alertVC, animated: true, completion: nil)
    }
}