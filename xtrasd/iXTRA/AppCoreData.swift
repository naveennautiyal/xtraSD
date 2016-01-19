//
//  ScanDirectory.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-11-12.
//  Copyright © 2015 iXTRA Technologies. All rights reserved.
//

import Foundation
import UIKit
import CoreData

public class AppCoreData
{
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    let fileManager = NSFileManager.defaultManager()
    let lib = Library()
    
    enum ObjectType
    {
        case Directory, File
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
    
    // walk initial directory
    func initiateWalkDirectory(url:NSURL)
    {
        print("walkDirectory of -> \(url)")
        let parentDir = NSEntityDescription.insertNewObjectForEntityForName("Directory", inManagedObjectContext: context) as! Directory
        parentDir.name = url.lastPathComponent
        parentDir.path = url.path
        parentDir.url = url
        
        walkDirectory(parentDir)
        saveContext()
    }
    
    // Now walk down the directory tree
    func walkDirectory(parent:Directory)
    {
        print("getting children ...")
        self.getChildren(parent)
        
        for child in parent.hasDirectories!
        {
           self.walkDirectory(child as! Directory)
        }
    }
    
    
    // get the child objects for the parent
    func getChildren(parent: Directory)
    {
        let fileObjects = lib.contentsOfAppBundle(parent.url!)
        
        for object in fileObjects
        {
            print("processing -> \(object)")
            if lib.isUrlDirectory(object) == "YES"
            {
                print("obj is a directory ...")
                // add object as a Directory
                self.addChildDir(parent, url: object)
            }
            else
            {
                print("obj is a file ...")
                
                self.addChildFile(parent, url: object)
            }
        }
        print("core data object check ...")
        print("parent.hasDirectories count -> \(parent.hasDirectories!.count)")
        print("parent.hasFiles count -> \(parent.hasFiles!.count)")
    }
    

    
    // MARK: CRUD Functions
    func addChildFile(parent:Directory, url: NSURL)
    {
        print(url.pathExtension)
        print(url.pathExtension?.isEmpty)
        
        // check if we recognize the file extension
        if !url.pathExtension!.isEmpty.boolValue {
            // add object as a File
            let childFile = NSEntityDescription.insertNewObjectForEntityForName("File", inManagedObjectContext: context) as! File
            childFile.name = url.lastPathComponent
            childFile.path = url.path
            childFile.url = url
            childFile.fileBelongsToADirectory = parent
            var createdDate: AnyObject?
            try! url.getResourceValue(&createdDate, forKey: NSURLCreationDateKey)
            childFile.createdAt = createdDate as? NSDate
            var accessedDate: AnyObject?
            try! url.getResourceValue(&accessedDate, forKey: NSURLContentAccessDateKey)
            childFile.accessedAt = accessedDate as? NSDate
            var modifiedDate: AnyObject?
            try! url.getResourceValue(&modifiedDate, forKey: NSURLContentModificationDateKey)
            childFile.modifiedAt = modifiedDate as? NSDate
            
            let mimetype = NSEntityDescription.insertNewObjectForEntityForName("Mimetype", inManagedObjectContext: context) as! Mimetype
            mimetype.fullname = Library().getMIMEType(url)
            mimetype.group = mimetype.fullname?.componentsSeparatedByString("/")[0]
            mimetype.member = mimetype.fullname?.componentsSeparatedByString("/")[1]
            
            childFile.mimetype = mimetype
            // add file relationship to currentDirectory
            parent.mutableSetValueForKey("hasFiles").addObject(childFile)
        }
    }
    
    func addChildDir(parent:Directory, url: NSURL)
    {
        let childDir = NSEntityDescription.insertNewObjectForEntityForName("Directory", inManagedObjectContext: context) as! Directory
        childDir.name = url.lastPathComponent
        childDir.path = url.path
        childDir.url = url
        childDir.directoryBelongsToADirectory = parent
        
        var createdDate: AnyObject?
        try! url.getResourceValue(&createdDate, forKey: NSURLCreationDateKey)
        childDir.createdAt = createdDate as? NSDate
        var accessedDate: AnyObject?
        try! url.getResourceValue(&accessedDate, forKey: NSURLContentAccessDateKey)
        childDir.accessedAt = accessedDate as? NSDate
        var modifiedDate: AnyObject?
        try! url.getResourceValue(&modifiedDate, forKey: NSURLContentModificationDateKey)
        childDir.modifiedAt = modifiedDate as? NSDate
        
        // add new directory record to rootDir set
        parent.mutableSetValueForKey("hasDirectories").addObject(childDir)
    }
    // 1. a file/dir is renamed

    func renameChildDir(child:Directory, newName: String)
    {
        // fetch child directory object
        let object = self.fetchObject(child, objectType: .Directory) as! Directory
        // update child name
        object.name = newName
        // update url
        object.url = child.url?.URLByDeletingLastPathComponent?.URLByAppendingPathComponent(newName, isDirectory: true)
        object.path = object.url?.path
        // save record
        self.saveContext()
        // return any errors in operation
    }
    func renameChildFile(child: File, newName: String)
    {
        // fetch child File object
        let object = self.fetchObject(child, objectType: .File) as! File
        // update child name
        object.name = newName
        // update url
        
        //Changed URLAppendPathExtension to URLAppendPathComponent as it was altering default file path after renaming it and creating error
        
        //object.url = child.url?.URLByDeletingLastPathComponent?.URLByAppendingPathExtension(newName)
        object.url = child.url?.URLByDeletingLastPathComponent?.URLByAppendingPathComponent(newName)
        object.path = object.url?.path
        //save record
        self.saveContext()
        // return any errors in operation
    }
    // 2. a file/dir is moved
    func moveChildDir(child:Directory, newParent: Directory)
    {
        // fetch child Directory object
        let object = self.fetchObject(child, objectType: .Directory) as! Directory
        // replace child.directoryBelongsToaDirectory with newParent
        object.directoryBelongsToADirectory = newParent
        // update url
        object.url = newParent.url?.URLByAppendingPathComponent(object.name!)
        object.path = object.url?.path
        // FIXME: need to update children as well
        
        // save record
        self.saveContext()
        // return any errors in operation
    }
    func moveChildFile(child: File, newParent: Directory)
    {
        // fetch child file object
        let object = self.fetchObject(child, objectType: .File) as! File
        // replace child.fileBelongsToaDirectory with newParent
        object.fileBelongsToADirectory = newParent
        // update url
        object.url = newParent.url?.URLByAppendingPathComponent(object.name!)
        object.path = object.url?.path
        // save record
        self.saveContext()
        // return any errors in operation
    }
    // 3. a file/dir is copied
    func copyChildDir(child:Directory, newParent: Directory)
    {
        // fetch child directory object
        let object = self.fetchObject(child, objectType: .Directory) as! Directory
        // create new child directory with newParent and newUrl
        let newChildDir = NSEntityDescription.insertNewObjectForEntityForName("Directory", inManagedObjectContext: context) as! Directory
        newChildDir.directoryBelongsToADirectory = newParent
        newChildDir.name = object.name
        newChildDir.url = newParent.url?.URLByAppendingPathComponent(newChildDir.name!)
        newChildDir.path = newChildDir.url?.path
        // FIXME: when copying a directory we need to copy its children as well
        self.getChildren(newChildDir)
        // save record
        
        // return any errors in operation
    }
    func copyChildFile(child:File, newParent:Directory)
    {
        let childURL = newParent.url?.URLByAppendingPathComponent(child.name!)
        self.addChildFile(newParent, url: childURL!)
//        
//        // fetch child file object
//        let object = self.fetchObject(child, objectType: .File)
//        // create new child file with newParent and newUrl
//        let newChildFile = NSEntityDescription.insertNewObjectForEntityForName("File", inManagedObjectContext: context) as! File
//        newChildFile.fileBelongsToADirectory = newParent
//        newChildFile.name = object.name
//        newChildFile.url = newParent.url?.URLByAppendingPathComponent(newChildFile.name!)
//        newChildFile.path = newChildFile.url?.path
        // save record
        self.saveContext()
        // return any errors in operation
    }
    // 4. a file/dir is deleted
    func deleteChildDir(child:Directory)
    {
        // fetch child directory object
        let object = self.fetchObject(child, objectType: .Directory)
        // delete record
        context.deleteObject(object as! NSManagedObject)
        self.saveContext()
        // return any errors in operation
    }
    func deleteChildFile(child:File)
    {
        // fetch child file object
        let object = self.fetchObject(child, objectType: .File)
        // delete record
        context.deleteObject(object as! NSManagedObject)
        self.saveContext()
        // return any errors in operation
    }
    
    // MARK: favourite/starred functions
    func starChildDir(child: Directory)
    {
        let object: Directory = self.fetchObject(child, objectType: .Directory) as! Directory
        object.starred = true
        self.saveContext()
    }
    
    func starChildFile(child: File)
    {
        let object: File = self.fetchObject(child, objectType: .File) as! File
        object.starred = true
        self.saveContext()
    }
    
    func setSelectTagForChildDir(child: Directory)
    {
        let object: Directory = self.fetchObject(child, objectType: .Directory) as! Directory
        object.isSelected = true
        self.saveContext()
    }
    
    func removeSelectTagForChildDir(child: Directory)
    {
        let object: Directory = self.fetchObject(child, objectType: .Directory) as! Directory
        object.isSelected = false
        self.saveContext()
    }
    
    func setSelectTagForChildFile(child: File)
    {
        let object: File = self.fetchObject(child, objectType: .File) as! File
        object.isSelected = true
        self.saveContext()
    }
    
    func removeSelectTagForChildFile(child: File)
    {
        let object: File = self.fetchObject(child, objectType: .File) as! File
        object.isSelected = false
        self.saveContext()
    }
    
    func removeSelectTagForAllChildren()
    {
        print("AppCoreData.removeSelectTagForAllChildren called")
        let dirs = self.fetchSelectedObjects(objects: .Directory) as! [Directory]
        
        for dir in dirs
        {
            dir.isSelected = false
        }
        
        let files = self.fetchSelectedObjects(objects: .File) as! [File]
        for file in files
        {
            file.isSelected = false
        }
        
        self.saveContext()
    }
    
    func getAllSelectedObjects() -> [AnyObject]?
    {
        print("AppCoreData.getAllSelectedObjects called")
        var results: [AnyObject]? = []
        results = self.fetchSelectedObjects(objects: .Directory)
        results?.appendContentsOf(self.fetchSelectedObjects(objects: .File))
        print("returning this many results -> \(results!.count)")
        return results
    }
    
    func getUrlsForSelectedObjects() -> [NSURL]
    {
        var results: [NSURL] = []
        let selectedObjects = self.getAllSelectedObjects()
        for object in selectedObjects!
        {
            results.append(object.url!!)
        }
        return results
    }
    
    func starAllSelectedObjects()
    {
        var objectCounter = 0
        print("AppCoreData.starAllSelectedObjects called")
        
        let dirs = self.fetchSelectedObjects(objects: .Directory) as! [Directory]
        for dir in dirs
        {
            dir.isStarred = true
            objectCounter += 1
        }
        let files = self.fetchSelectedObjects(objects: .File) as! [File]
        
        for file in files
        {
            file.isStarred = true
            objectCounter += 1
        }
        
        print("starred this many objects -> \(objectCounter)")
        self.saveContext()
    }
    
    
    
    // MARK: utility functions

    
    func batchEraseStoredData()
    {
        // Delete Directories
        let dirEntity = NSEntityDescription.entityForName("Directory", inManagedObjectContext: context)
        let dirRequest = NSFetchRequest()
        dirRequest.entity = dirEntity
        dirRequest.includesPropertyValues = false
        
        let dirs = try! context.executeFetchRequest(dirRequest)
        
        for dir in dirs
        {
            context.deleteObject(dir as! NSManagedObject)
        }
        
        //Delete Files
        let fileEntity = NSEntityDescription.entityForName("File", inManagedObjectContext: context)
        let fileRequest = NSFetchRequest()
        fileRequest.entity = fileEntity
        fileRequest.includesPropertyValues = false
        
        let files = try! context.executeFetchRequest(fileRequest)
        
        for file in files
        {
            context.deleteObject(file as! NSManagedObject)
        }
        
    }

    // common function to fetch object
    func fetchObject(object: AnyObject, objectType: ObjectType) -> AnyObject
    {
        let request = NSFetchRequest()
        var result: AnyObject?
        
        switch objectType
        {
        case .Directory:
            // if Directory object
            // create dirEntity fetch request
            let dirEntity = NSEntityDescription.entityForName("Directory", inManagedObjectContext: context)
            request.entity = dirEntity
            request.includesPropertyValues = false
            
        case .File:
            // if File object
            // create fileEntity fetch request
            let fileEntity = NSEntityDescription.entityForName("File", inManagedObjectContext: context)
            request.entity = fileEntity
            request.includesPropertyValues = false
        }
        
        let predicate = NSPredicate(format: "(url = %@)", object.url!!)
        request.predicate = predicate
        
        do
        {
            let results = try context.executeFetchRequest(request)
            if results.count > 1
            {
                NSLog("Error -> duplicate entries in coreData!!!")
            }
            else
            {
                result = results[0]
            }
        }
        catch let error as NSError
        {
            NSLog("Error: ScanDirectory.fetchObject -> \(error)")
        }
        return result!
    }
    
    func fetchSelectedObjects(objects objectType: ObjectType) -> [AnyObject]
    {
        let request = NSFetchRequest()
        var results: [AnyObject] = []
        
        switch objectType
        {
        case .Directory:
            // if Directory object
            // create dirEntity fetch request
            let dirEntity = NSEntityDescription.entityForName("Directory", inManagedObjectContext: context)
            request.entity = dirEntity
            request.includesPropertyValues = false
            
        case .File:
            // if File object
            // create fileEntity fetch request
            let fileEntity = NSEntityDescription.entityForName("File", inManagedObjectContext: context)
            request.entity = fileEntity
            request.includesPropertyValues = false
        }
        
        let predicate = NSPredicate(format: "(selected = %d)", 1)
        request.predicate = predicate
        
        do
        {
            results = try context.executeFetchRequest(request)
        }
        catch let error as NSError
        {
            NSLog("Error: ScanDirectory.fetchObject -> \(error)")
        }
        return results

    }
    
    func fetchObjectAtUrl(url: NSURL) -> AnyObject
    {
        let request = NSFetchRequest()
        var result: AnyObject!
        
        // create dirEntity fetch request
        let dirEntity = NSEntityDescription.entityForName("Directory", inManagedObjectContext: context)
        request.entity = dirEntity
        request.includesPropertyValues = false
        
        let predicate = NSPredicate(format: "(url = %@)", url)
        request.predicate = predicate
        
        do
        {
            let results = try context.executeFetchRequest(request)
            if results.count > 1
            {
                NSLog("Error -> duplicate entries in coreData!!!")
            }
            else
            {
                result = results[0]
            }
        }
        catch let error as NSError
        {
            NSLog("Error: ScanDirectory.fetchObject -> \(error)")
        }
        
        return result

    }
    func fetchParentObjectAtURL(url: NSURL) -> Directory
    {
        let request = NSFetchRequest()
        var result: Directory!
        
        // create dirEntity fetch request
        let dirEntity = NSEntityDescription.entityForName("Directory", inManagedObjectContext: context)
        request.entity = dirEntity
        request.includesPropertyValues = false

        let predicate = NSPredicate(format: "(url = %@)", url)
        request.predicate = predicate
        
        do
        {
            let results = try context.executeFetchRequest(request)
            if results.count > 1
            {
                NSLog("Error -> duplicate entries in coreData!!!")
            }
            else
            {
                result = results[0] as! Directory
            }
        }
        catch let error as NSError
        {
            NSLog("Error: ScanDirectory.fetchObject -> \(error)")
        }
        
        return result
    }
    
    enum mediaType
    {
        case Image, Video, Audio
    }
    
    func getMediaDirectoryObject(media: mediaType) -> Directory
    {
        let request = NSFetchRequest()
        var url: NSURL!
        var name: String!
        var result: Directory?
        var results: NSArray!
        
        let dirEntity = NSEntityDescription.entityForName("Directory", inManagedObjectContext: context)
        request.entity = dirEntity
        request.includesPropertyValues = false
        
        switch media
        {
        case .Image:
            url = RootController().getLocalImagePathUrl()
            name = "images"
        case .Video:
            url = RootController().getLocalVideoPathUrl()
            name = "videos"
        case .Audio:
            url = RootController().getLocalAudioPathUrl()
            name = "audio"
        }
        
        print("url was set to -> \(url)")
        //FIXME: must search based on url. Problem is url from RootController starts with /var/mobile and from within CoreData /private/var/mobile
//        let predicate = NSPredicate(format: "(url = %@)", url)
        let predicate = NSPredicate(format: "(name = %@)", name)
        request.predicate = predicate
        
        
        do
        {
           results = try context.executeFetchRequest(request)
           NSLog("results received -> %d", results.count)
        }
        catch let error as NSError
        {
            NSLog("Error: ScanDirectory.fetchObject -> \(error)")
        }
        
        switch results.count
        {
        case 0:
            NSLog("Error -> No results found")
            break
        case _ where results.count > 1 :
            NSLog("Error -> duplicate entries in core data !!!!")
            break
        default:
            result = results[0] as? Directory
            print("result url -> \(result!.url)")
        }

        return result!
    }
    
    //get "documents" directory
    func getDocumentsDirectoryObject() -> Directory
    {
        let request = NSFetchRequest()
        var url: NSURL!
        var name: String!
        var result: Directory?
        var results: NSArray!
        
        let dirEntity = NSEntityDescription.entityForName("Directory", inManagedObjectContext: context)
        request.entity = dirEntity
        request.includesPropertyValues = false
 
        var paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask, true)
        let iOSApplicationDirectory: AnyObject = paths[0]
        url = NSURL(fileURLWithPath: iOSApplicationDirectory as! String).URLByAppendingPathComponent("Documents")
        name = "Documents"
 
        
        print("url was set to -> \(url)")
        //FIXME: must search based on url. Problem is url from RootController starts with /var/mobile and from within CoreData /private/var/mobile
        //        let predicate = NSPredicate(format: "(url = %@)", url)
        let predicate = NSPredicate(format: "(name = %@)", name)
        request.predicate = predicate
        
        
        do
        {
            results = try context.executeFetchRequest(request)
            NSLog("results received -> %d", results.count)
        }
        catch let error as NSError
        {
            NSLog("Error: ScanDirectory.fetchObject -> \(error)")
        }
        result = results[0] as? Directory
        print("result url -> \(result!.url)")
        
        return result!
    }
    
    // MARK: Preferences
    // initiate Preference Object
    func initiatePreferences() -> Preferences
    {
        print("initiating Preferences ...")
        // check if a preference record exists, if it does do nothing
        
        let newPreferenceSet = NSEntityDescription.insertNewObjectForEntityForName("Preferences", inManagedObjectContext: context) as! Preferences
        newPreferenceSet.persistentFilter = false
        newPreferenceSet.chargeOnly = true
        newPreferenceSet.cameraAutosync = false
        newPreferenceSet.autoSyncMode = .Copy
        newPreferenceSet.defaultView = .AllFiles
        newPreferenceSet.defaultSort = .Alphabetical
        
        self.saveContext()
        
        return newPreferenceSet
    }
    
    func destroyPreferences()
    {
        let request = NSFetchRequest()
        let preferenceEntity = NSEntityDescription.entityForName("Preferences", inManagedObjectContext: context)
        request.entity = preferenceEntity
        request.includesPropertyValues = false
        
        let preferences = try! context.executeFetchRequest(request)
        
        for set in preferences
        {
            context.deleteObject(set as! NSManagedObject)
        }
        
        self.saveContext()
    }
    
    // fetchPreferenceObject -> dataSet
    func fetchPreferences() -> Preferences
    {
        var result: Preferences!
        let request = NSFetchRequest()
        
        let preferenceEntity = NSEntityDescription.entityForName("Preferences", inManagedObjectContext: context)
        request.entity = preferenceEntity
        request.includesPropertyValues = false
        
        do
        {
            let results = try context.executeFetchRequest(request)
            switch results.count
            {
            case 0:
                // There is no preferences set in CoreData
                // Create a new preference set
                NSLog("No Preferences set")
                result = self.initiatePreferences()
            case _ where results.count > 1:
                // CoreData preferences is corrupted
                // destroy all preferences and create a new one
                NSLog("More than one prefence set! ... reseting preferences")
                self.destroyPreferences()
                result = self.initiatePreferences()
            default:
                // All is good return the only set
                result = results[0] as! Preferences
            }
        }
        catch let error as NSError
        {
            print("Error in fetching preferences -> \(error)")
        }
        
        return result
    }

}