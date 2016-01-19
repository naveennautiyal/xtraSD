//
//  CellSelection.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-11-23.
//  Copyright © 2015 iXTRA Technologies. All rights reserved.
//

import UIKit

class CellSelection: UIView
{
    var checked: Bool = false
    let xShim: CGFloat = 8.0
    let yShim: CGFloat = 25.0
    let diameter: CGFloat = 14.0
    
    override func drawRect(rect: CGRect)
    {
        super.drawRect(rect)

        if self.checked.boolValue
        {
            self.drawRectChecked(rect)
        }
        else
        {
            self.drawRectOpenCircle(rect)
        }
    }
    
    func setCheckedCell(checked:Bool)
    {
        self.checked = checked
        self.setNeedsDisplay()
    }
    
    func drawRectChecked(rect: CGRect)
    {
        print(rect)
        //// Color Declarations
        let colour = UIColor(red: 74/255, green: 146/255, blue: 226/255, alpha: 1.000)
        
        //// Oval Drawing
        let ovalPath = UIBezierPath(ovalInRect: CGRectMake(frame.minX + xShim, frame.minY + yShim, diameter, diameter))

        colour.setFill()
        ovalPath.fill()
        UIColor.lightGrayColor().setStroke()
        ovalPath.lineWidth = 1
        ovalPath.stroke()
    }
    
    func drawRectOpenCircle(rect: CGRect)
    {
        //// Oval Drawing
        let colour = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1.00)
        let ovalPath = UIBezierPath(ovalInRect: CGRectMake(frame.minX + xShim, frame.minY + yShim, diameter, diameter))
        colour.setFill()
        ovalPath.fill()
        UIColor.lightGrayColor().setStroke()
        ovalPath.lineWidth = 1
        ovalPath.stroke()
    }
}
