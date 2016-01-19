
//  Library.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-09-02.
//  Copyright (c) 2015 iXTRA Technologies. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import CoreData


class Library
{
    // TODO: Need an enumerator in FileAccess.m
    
    func contentsOfAppBundle(bundleUrl:NSURL) -> [NSURL]
    {
        let propertiesToGet =
        [
            NSURLIsDirectoryKey,
            NSURLIsReadableKey,
            NSURLCreationDateKey,
            NSURLContentAccessDateKey,
            NSURLContentModificationDateKey,
            NSURLLocalizedNameKey,
        ]
        
        let fileManager = NSFileManager.defaultManager()
        
        let results = try! fileManager.contentsOfDirectoryAtURL(
            bundleUrl,
            includingPropertiesForKeys: propertiesToGet,
            options: []
        )
        return results
    }

    func stringValueOfBoolProperty(property: String, url: NSURL) -> String
    {
        var value:AnyObject?
        var boolValue: String?
    
        do
        {
            try url.getResourceValue(&value, forKey: property)
            
            if let number = value as? NSNumber
            {
                boolValue = (number.boolValue ? "YES":"NO")
            }
        }
        catch let error as NSError
        {
                print("error in Library.stringValueOfBoolProperty:url.getResourceValue -> \(error)")
        }
        
        return boolValue!
    }

    func isUrlDirectory(url: NSURL) -> String
    {
        return stringValueOfBoolProperty(NSURLIsDirectoryKey, url: url)
    }

    func isUrlReadable(url:NSURL) -> String
    {
        return stringValueOfBoolProperty(NSURLIsReadableKey, url: url)
    }
    


    func dateOfType(type: String, url: NSURL) -> NSDate?
    {
        
        var value:AnyObject?
        var dateValue: NSDate?
        
        do
        {
            try url.getResourceValue(&value, forKey: type)
            
            if let date = value as? NSDate
            {
                dateValue = date
            }
            
        }
        catch let error as NSError
        {
            print("error in Library.dateOfType:url.getResourceValue -> \(error)")
        }
        
        return dateValue
    }

    // function to return timestamp for writing media files
    func isoDate() -> String
    {
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateFormat = "yyDDDHHmmss"
        dateFormatter.timeZone = NSTimeZone.localTimeZone()
        
        return dateFormatter.stringFromDate(NSDate())
    }
    
    func getImages(url:NSURL) -> [UIImage]
    {
        var imageArray = [UIImage]()
        let images = self.contentsOfAppBundle(url)
        for image in images
        {
            imageArray.append(UIImage(contentsOfFile: image.path!)!)
        }
        
        return imageArray
        
    }

    // get file MIME Type from UTI
    func getMIMEType(fileUrl:NSURL) -> String
    {
        // get the file extension
        let fileExtension = fileUrl.pathExtension!
        
        // get UTI class
        let type:CFStringRef = (UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil)?.takeRetainedValue())!
        
        // get MIME Type from UTI class
        let mimeType = UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType)?.takeRetainedValue()
        
        return mimeType! as String
    }
    
    func getMimeClass(fileUrl: NSURL) -> String
    {
        return self.getMIMEType(fileUrl).componentsSeparatedByString("/")[0]
    }
    
    func getMimetypeMember(fileUrl: NSURL) -> String
    {
        return self.getMIMEType(fileUrl).componentsSeparatedByString("/")[1]
    }
    
    func isFileImage(fileUrl: NSURL) -> Bool
    {
        var boolValue: Bool!
        let mimeClass = self.getMimeClass(fileUrl)
        boolValue = (mimeClass == "image" ? true : false)
        return boolValue
    }
    
    func isFileVideo(fileUrl: NSURL) -> Bool
    {
        var boolValue: Bool!
        let mimeClass = self.getMimeClass(fileUrl)
        boolValue = (mimeClass == "video" ? true : false)
        return boolValue
    }
    
    func isFileAudio(fileUrl:NSURL) -> Bool
    {
        var boolValue: Bool!
        let mimeClass = self.getMimeClass(fileUrl)
        boolValue = (mimeClass == "audio" ? true : false)
        return boolValue
    }

    func getMimeTypeImage(mimeType: String) -> UIImage
    {
        var image: UIImage = UIImage()
        
        switch mimeType
        {
            // TODO: put the following in a library function; duplicate of PeripheralViewController
        case "png":   image = UIImage(named: "png_file")!
        case "jpeg":  image = UIImage(named: "jpg_file")!
        case "pdf":   image = UIImage(named: "pdf_file")!
        case "html":  image = UIImage(named: "html_file")!
        case "mp3", "mpeg":   image = UIImage(named: "mp3_file")!
        case "quicktime":   image = UIImage(named: "mov_file")!
        case "plain": image = UIImage(named: "txt_file")!
        default: print("no image selection for file")
        }
        
        return image
    }
    
    func getMimeTypeImageForURL(url: NSURL) -> UIImage
    {
        let fullMimeType = self.getMIMEType(url)
        let mimeType = fullMimeType.componentsSeparatedByString("/")[1]
        return self.getMimeTypeImage(mimeType)
    }
    
    // MARK: UI enhancement elements
    func addGradient() -> CAGradientLayer
    {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.startPoint = CGPoint(x:0.5, y:0)
        gradientLayer.endPoint = CGPoint(x:0.5, y:1)
        let colors: [CGColorRef] = [
            UIColor.whiteColor().colorWithAlphaComponent(0.2).CGColor,
            UIColor(red:0.26,green:0.26,blue:0.26, alpha: 0.6).CGColor
        ]
        gradientLayer.colors = colors
        return gradientLayer
    }

}

