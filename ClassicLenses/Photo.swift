//
//  Photo.swift
//  VirtualTourist
//
//  Created by Keng Siang Lee on 19/9/15.
//  Copyright (c) 2015 KSL. All rights reserved.
//

import UIKit
import CoreData

@objc(Photo)

class Photo : NSManagedObject {
    
    @NSManaged var imageFileName: String?
    @NSManaged var timestamp: NSDate  //for sorting during fetching to get the same order
    
    @NSManaged var lens: Lens?
    
    //standard core data init method
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(imageFileName: String?, context: NSManagedObjectContext) {
        
        //add entity to context
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        //set attributes
        self.imageFileName = imageFileName
        self.timestamp = NSDate()
    }
    
    override func prepareForDeletion() {
        
        //remove the local image file
        if let photoImageFileName = imageFileName {
            if photoImageFileName != "" {
                let imageFilePath = FileHelper.getDocumentPathForFile(photoImageFileName)
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(imageFilePath)
                } catch {
                    
                }
            }
        }
        
    }
    
}