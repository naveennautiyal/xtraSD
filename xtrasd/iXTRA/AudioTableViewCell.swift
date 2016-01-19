//
//  MediaTableViewCell.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-11-05.
//  Copyright © 2015 iXTRA Technologies. All rights reserved.
//

import UIKit
import AVFoundation

class AudioTableViewCell: SWTableViewCell, AVAudioPlayerDelegate
{
    let appCoreData = AppCoreData()
    var audioPlayer: AVAudioPlayer!
    var playBackTimer: NSTimer!
    var fileObject: File!
    

    @IBOutlet weak var play: UIButton!
    @IBOutlet weak var stop: UIButton!
    
    @IBOutlet weak var fileName: UILabel!
    
    @IBOutlet weak var progressSlider: UISlider!
    
    @IBOutlet weak var starImage: UIImageView!
    
    @IBOutlet weak var cellSelection: TableViewCellSelection!
    
    @IBAction func playAudio(sender: AnyObject)
    {
        if let player = audioPlayer
        {
            let object = appCoreData.fetchObject(fileObject, objectType: .File) as! File
            object.accessedAt = NSDate()
            appCoreData.saveContext()
            
            player.play()
            self.togglePlayStopButtons()
            progressSlider.maximumValue = Float(player.duration)
            progressSlider.value = 0.0
            playBackTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "updateProgressBar:", userInfo: nil, repeats: false)
        }
    }
    
    @IBAction func stopAudio(sender: AnyObject)
    {
        if let player = audioPlayer
        {
            player.stop()
            self.togglePlayStopButtons()
        }
    }
    
    @IBAction func seekToTime(sender: AnyObject) {
        audioPlayer?.currentTime = NSTimeInterval(progressSlider.value)
    }

    func togglePlayStopButtons()
    {
        self.play.hidden = !self.play.hidden
        self.stop.hidden = !self.stop.hidden

        if self.play.hidden
        {
            self.bringSubviewToFront(self.stop)
        }

        if self.stop.hidden
        {
            self.bringSubviewToFront(self.play)
        }
    }
    
    func updateProgressBar(timer: NSTimer)
    {
        progressSlider.value = Float(audioPlayer.currentTime)
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
