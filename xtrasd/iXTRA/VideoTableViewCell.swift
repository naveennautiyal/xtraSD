//
//  VideoTableViewCell.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-11-05.
//  Copyright © 2015 iXTRA Technologies. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class VideoTableViewCell: SWTableViewCell
{
    
    let movieController = AVPlayerViewController()

    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var stopButton: UIButton!
    
    @IBOutlet weak var cellSelection: TableViewCellSelection!
    
    @IBOutlet weak var starImage: UIImageView!
    
    @IBAction func playVideoInPlace(sender: AnyObject)
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemDidReachEnd:", name: AVPlayerItemDidPlayToEndTimeNotification, object: movieController.player?.currentItem)
        togglePlayStopButtons()
        movieController.player!.play()
        
    }

    func playerItemDidReachEnd(notification: NSNotification)
    {
        print("received notification -> reseting video to zero time")
        movieController.player?.seekToTime(kCMTimeZero)
        togglePlayStopButtons()
    }
    
    
    func togglePlayStopButtons()
    {
        self.playButton.hidden = !self.playButton.hidden
        self.stopButton.hidden = !self.stopButton.hidden
        
        if self.playButton.hidden
        {
            self.bringSubviewToFront(self.stopButton)
        }
        
        if self.stopButton.hidden
        {
            self.bringSubviewToFront(self.playButton)
        }
    }

    
    @IBAction func stopVideoPlayback(sender: AnyObject)
    {
        togglePlayStopButtons()
        movieController.player?.pause()
    }
    
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
