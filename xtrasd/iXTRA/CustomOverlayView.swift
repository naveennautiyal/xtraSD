//
//  CustomOverlayView.swift
//  xtraSD
//
//  Created by Optimus-66 on 12/22/15.
//  Copyright © 2015 iXTRA Technologies. All rights reserved.
//

import UIKit

protocol CustomOverlayDelegate{
    func didCancel(overlayView:CustomOverlayView)
    func didShoot(overlayView:CustomOverlayView)
    func changeCamera(overlayView:CustomOverlayView)
    func changeCaptureMode(overlayView:CustomOverlayView)
}

class CustomOverlayView: UIView {
    
    
    @IBOutlet weak var cameraActionButton: UIButton!
    
    var delegate:CustomOverlayDelegate! = nil
    
    //Used to switch between front and rear camera
    @IBAction func switchCamera(sender: AnyObject)
    {
        delegate.changeCamera(self)
    }
    
    //Used to switch between video and photo capture modes
    @IBAction func switchCaptureMode(sender: AnyObject)
    {
        delegate.changeCaptureMode(self)
    }
    
    //Called when photo is captured
    @IBAction func shoot(sender: AnyObject)
    {
        delegate.didShoot(self)
    }
    //Called when Done button is pressed
    @IBAction func cancel(sender: AnyObject)
    {
        delegate.didCancel(self)
    }

}
