//
//  Preferences+CoreDataProperties.swift
//  xtraSD
//
//  Created by Fadi Asfour on 2015-12-08.
//  Copyright © 2015 iXTRA Technologies. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Preferences {

    @NSManaged var autosyncModeValue: Int32
    @NSManaged var cameraAutosync: Bool
    @NSManaged var chargeOnly: Bool
    @NSManaged var defaultSortValue: Int32
    @NSManaged var defaultViewValue: Int32
    @NSManaged var persistentFilter: Bool
    @NSManaged var persistentFilterValue: Int32
    @NSManaged var defaultSortSet: Bool

    
    enum AutoSyncMode: Int32
    {
        case Copy, Move
    }
    
    enum DefaultView: Int32
    {
        case AllFiles, AllMedia, Document, Audio, Video, Photo
    }
    
    enum DefaultSort: Int32
    {
        case Alphabetical, Recent, StarredAlphabetical, StarredRecent
    }
    
    
    var autoSyncMode: AutoSyncMode
        {
        get
        {
            return AutoSyncMode(rawValue: self.autosyncModeValue)!
        }
        
        set
        {
            self.autosyncModeValue = newValue.rawValue
        }
    }
    
    var isDefaultSortSet: Bool
        {
        get
        {
            return defaultSortSet
        }
        set
        {
            self.defaultSortSet = newValue
        }
    }
    
    var persistentFilterMode: DefaultView
        {
        get
        {
            return DefaultView(rawValue: self.persistentFilterValue)!
        }
        set
        {
            self.persistentFilterValue = newValue.rawValue
        }
    }
    
    var defaultView: DefaultView
        {
        get
        {
            return DefaultView(rawValue: self.defaultViewValue)!
        }
        
        set
        {
            self.defaultViewValue = newValue.rawValue
        }
        
    }
    
    var defaultSort: DefaultSort
        {
        get
        {
            return DefaultSort(rawValue: self.defaultSortValue)!
        }
        
        set
        {
            self.defaultSortValue = newValue.rawValue
        }
    }
    
    var getDefaultView: String
        {
        get
        {
            switch DefaultView(rawValue: self.defaultViewValue)!
            {
            case .AllFiles: return "All Files"
            case .AllMedia: return "All Media"
            case .Document: return "Document"
            case .Audio: return "Audio"
            case .Video: return "Video"
            case .Photo: return "Photo"
            }
        }
    }
    
    var getDefaultSort: [NSSortDescriptor]
        {
        get
        {
            switch DefaultSort(rawValue: self.defaultSortValue)!
            {
            case .Alphabetical: return [NSSortDescriptor(key: "name", ascending: true)]
            case .Recent: return [NSSortDescriptor(key: "modifiedAt", ascending: true)]
            case .StarredAlphabetical: return [NSSortDescriptor(key: "starred", ascending: false), NSSortDescriptor(key: "name", ascending: true)]
            case .StarredRecent: return [NSSortDescriptor(key: "starred", ascending: false), NSSortDescriptor(key: "modifiedAt", ascending: true)]
            }
        }
        
    }
    
    var getDefaultSortName: String
        {
        get
        {
            switch DefaultSort(rawValue: self.defaultSortValue)!
            {
            case .Alphabetical: return "Alphabetical"
            case .Recent: return "Recent"
            case .StarredAlphabetical: return "Starred, Alphabetical"
            case .StarredRecent: return "Starred, Recent"
            }
        }
    }
    
}
