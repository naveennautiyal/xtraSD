//
//  FolderCollectionViewCellController.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-11-04.
//  Copyright © 2015 iXTRA Technologies. All rights reserved.
//

import UIKit

class FolderCollectionViewCell: UICollectionViewCell
{
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var folderName: UILabel!
    @IBOutlet weak var cellSelection: CellSelection!
    @IBOutlet weak var starImage: UIImageView!
    
    func activateCellSelection(state:Bool)
    {
        if state
        {
            self.bringSubviewToFront(cellSelection)
            self.cellSelection.hidden = false
        }
        else
        {
            self.cellSelection.sendSubviewToBack(cellSelection)
            self.cellSelection.hidden = true
        }
        
    }
    
 }
