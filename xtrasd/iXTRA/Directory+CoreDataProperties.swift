//
//  Directory+CoreDataProperties.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-11-26.
//  Copyright © 2015 iXTRA Technologies. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Directory {

    @NSManaged var name: String?
    @NSManaged var path: String?
    @NSManaged var selected: NSNumber?
    @NSManaged var starred: NSNumber?
    @NSManaged var url: NSURL?
    @NSManaged var createdAt: NSDate?
    @NSManaged var modifiedAt: NSDate?
    @NSManaged var accessedAt: NSDate?
    @NSManaged var directoryBelongsToADirectory: Directory?
    @NSManaged var hasDirectories: NSSet?
    @NSManaged var hasFiles: NSSet?

    
    var isSelected:Bool
    {
        get
        {
            return Bool(selected!)
        }
        
        set
        {
            selected = NSNumber(bool: newValue)
        }
    }
    
    var isStarred: Bool
    {
        get
        {
            return Bool(starred!)
        }
        set
        {
            starred = NSNumber(bool: newValue)
        }
    }


}
