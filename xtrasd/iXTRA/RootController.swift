//
//  RootController.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-08-18.
//  Copyright (c) 2015 iXTRA Technologies. All rights reserved.
//

import Foundation
import UIKit
import XTR100
import CoreData

// global variables accross app

public let device: FileAccess = FileAccess.sharedFileAccess()
public var accessoryIsConnected: Bool = false

class RootController: UINavigationController
{
    let fileManager = NSFileManager.defaultManager()
    let lib = Library()
    let appCoreData = AppCoreData()
    // File paths
    var localUrl: NSURL!
    var localImagePathUrl: NSURL!
    var localVideoPathUrl: NSURL!
    var localAudioPathUrl: NSURL!
    
    // return paths
    func getLocalImagePathUrl() -> NSURL
    {
        if localImagePathUrl == nil
        {
            self.setMediaPaths()
        }
        return localImagePathUrl
    }
    
    func getLocalVideoPathUrl() -> NSURL
    {
        if localVideoPathUrl == nil
        {
            self.setMediaPaths()
        }
        return localVideoPathUrl
    }
    
    func getLocalAudioPathUrl() -> NSURL
    {
        if localAudioPathUrl == nil
        {
            self.setMediaPaths()
        }
        return localAudioPathUrl
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // activate notification center for media collection view
        self.setMediaPaths()
        self.createDummyFiles()
        
        self.checkConnection()
        
        // enumerate volume
        do
        {
            let rootURL = try fileManager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
            // empty out core data before scanning the volume in
            appCoreData.batchEraseStoredData()
            appCoreData.initiateWalkDirectory(rootURL)
            
        } catch let error as NSError {
            NSLog("Error in getting rootURL ->%@", error)
        }

        // general UI settings
        self.toolbar.translucent = true
        self.toolbar.alpha = 0.0
        self.toolbar.barTintColor = UIColor.clearColor()
        

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func createDummyFiles()
    {
        
        var paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask, true)
        let iOSApplicationDirectory: AnyObject = paths[0]
        
        
        // Create iOS Directories
        let dirArray = ["Documents", "Library"]
        var docDir:AnyObject?
        var libDir:AnyObject?
        for dir in dirArray  {
            let deliveryPath = NSURL(fileURLWithPath: iOSApplicationDirectory as! String).URLByAppendingPathComponent(dir)
            if dir == "Documents" {
                docDir = deliveryPath
            } else {
                libDir = deliveryPath
            }
            do {
                try fileManager.createDirectoryAtURL(deliveryPath, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                print("Cannot create directory -> error: \(error)")
            }
            
        }
        
        // create directory and a text file into Document dir
        let newDir = docDir?.URLByAppendingPathComponent("New Folder")
        do {
            try fileManager.createDirectoryAtURL(newDir!, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Cannot create directory -> error: \(error)")
        }
        
        var newFilePath = newDir?.URLByAppendingPathComponent("test_1.txt")
        var text = "Hello World!"
        do {
            try text.writeToURL(newFilePath!, atomically: false, encoding: NSUTF8StringEncoding)
        } catch let error as NSError {
            print("Cannot write to file -> error: \(error)")        }
        
        
        newFilePath = libDir?.URLByAppendingPathComponent("test_1.txt")
        text = "Hello World! from Library"
        do {
            try text.writeToURL(newFilePath!, atomically: false, encoding: NSUTF8StringEncoding)
        } catch let error as NSError {
            print("Cannot write to file -> error: \(error)")
        }
        
        newFilePath = libDir?.URLByAppendingPathComponent("test_2.txt")
        text = "You're still here???\n - from Library"
        do {
            try text.writeToURL(newFilePath!, atomically: false, encoding: NSUTF8StringEncoding)
        } catch let error as NSError {
            print("Cannot write to file -> error: \(error)")
        }
        
        newFilePath = NSURL(fileURLWithPath: iOSApplicationDirectory as! String).URLByAppendingPathComponent("logData.txt")
        text = "Application Log File\n"
        do {
            try text.writeToURL(newFilePath!, atomically: false, encoding: NSUTF8StringEncoding)
        } catch let error as NSError {
            print("Cannot write to file -> error: \(error)")
        }

    }
    
    // create media paths
    func setMediaPaths()
    {
        // Create paths to output images
        // for now we will write to the application folder
        
        do
        {
            localUrl = try fileManager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
            localUrl = localUrl?.URLByAppendingPathComponent("media", isDirectory: true)
        }
        catch let error as NSError
        {
            NSLog("Error -> %@", error)
        }
        
        do
        {
            // create media directory if it does not exist
            try fileManager.createDirectoryAtURL(localUrl!, withIntermediateDirectories: true, attributes: nil)
            
        }
        catch let error as NSError
        {
            NSLog("error creating media dir -> %@", error)
        }
        
        do
        {
            // create images directory if it does not exist
            localImagePathUrl = localUrl?.URLByAppendingPathComponent("images", isDirectory: true)
            try fileManager.createDirectoryAtURL(localImagePathUrl!, withIntermediateDirectories: true, attributes: nil)
        }
        catch let error as NSError
        {
            NSLog("error creating image dir -> %@", error)
        }
        
        do
        {
            // create videos directory if it does not exist
            localVideoPathUrl = localUrl?.URLByAppendingPathComponent("videos", isDirectory: true)
            try fileManager.createDirectoryAtURL(localVideoPathUrl!, withIntermediateDirectories: true, attributes: nil)
        }
        catch let error as NSError
        {
            NSLog("error creating videos dir -> %@", error)
        }
        
        do
        {
            // create audio directory if it does not exist
            localAudioPathUrl = localUrl?.URLByAppendingPathComponent("audio", isDirectory: true)
            try fileManager.createDirectoryAtURL(localAudioPathUrl!, withIntermediateDirectories: true, attributes: nil)
        }
        catch let error as NSError
        {
            NSLog("error creating audio dir -> %@", error)
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
    }
    
}
