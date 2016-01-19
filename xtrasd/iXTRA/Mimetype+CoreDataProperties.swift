//
//  Mimetype+CoreDataProperties.swift
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

extension Mimetype {

    @NSManaged var fullname: String?
    @NSManaged var group: String?
    @NSManaged var member: String?
    @NSManaged var belongsToFile: File?

}
