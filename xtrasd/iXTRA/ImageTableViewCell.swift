//
//  ImageTableViewCell.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-11-05.
//  Copyright © 2015 iXTRA Technologies. All rights reserved.
//

import UIKit

class ImageTableViewCell: SWTableViewCell
{
    
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var fileName: UILabel!
    @IBOutlet weak var cellSelection: TableViewCellSelection!
    @IBOutlet weak var starImage: UIImageView!
    
    //Show/Hide select circle in tableViewCell
    func activateTableViewCellSelection(state:Bool)
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
