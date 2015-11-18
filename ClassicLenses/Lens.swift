//
//  Lens.swift
//  ClassicLenses
//
//  Created by Keng Siang Lee on 2/11/15.
//  Copyright © 2015 KSL. All rights reserved.
//

import Foundation
import UIKit
import CoreData

@objc(Lens)

class Lens: NSManagedObject {
    
    @NSManaged var name: String?
    @NSManaged var desc: String?
    @NSManaged var brand: String?
    @NSManaged var img: String?
    @NSManaged var focalLength: String?
    @NSManaged var aperture: String?
    @NSManaged var minFocusDist: String?
    @NSManaged var lensConstruction: String?
    @NSManaged var apertureBlades: String?
    @NSManaged var angleOfView: String?
    @NSManaged var mount: String?
    @NSManaged var length: String?
    @NSManaged var weight: String?
    @NSManaged var dateUpdated: String?
    @NSManaged var imageFileName: String?
    
    @NSManaged var representativePrice: Float
    
    @NSManaged var prices: [Price]
    @NSManaged var photos: [Photo]
    
    //standard core data init method
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(name: String?, desc: String?, brand: String?, img: String?, focalLength: String?, aperture: String?, minFocusDist: String?, lensConstruction: String?, apertureBlades: String?, angleOfView: String?, mount: String?, length: String?, weight: String?, dateUpdated: String?, representativePrice: Float, autoCreateImageOnDisk: Bool = true, context: NSManagedObjectContext) {
        
        //add entity to context
        let entity = NSEntityDescription.entityForName("Lens", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        //set attributes
        self.name = name
        self.desc = desc
        self.brand = brand
        self.img = img
        self.focalLength = focalLength
        self.aperture = aperture
        self.minFocusDist = minFocusDist
        self.lensConstruction = lensConstruction
        self.apertureBlades = apertureBlades
        self.angleOfView = angleOfView
        self.mount = mount
        self.length = length
        self.weight = weight
        self.dateUpdated = dateUpdated
        self.representativePrice = representativePrice
        
        if self.img == "loading" {
            self.imageFileName = "loading"
        } else {
            //create the actual file on disk
            if autoCreateImageOnDisk {
                self.createImageOnDisk()
            }
        }
    }
    
    convenience init(dict: [String: AnyObject], representativePrice: Float, autoCreateImageOnDisk: Bool = true, context: NSManagedObjectContext) {
        self.init(
            name: dict["name"] as? String,
            desc: dict["description"] as? String,
            brand: dict["brand"] as? String,
            img: dict["img"] as? String,
            focalLength: dict["focal_length"] as? String,
            aperture: dict["aperture_ratio"] as? String,
            minFocusDist: dict["minimum_focus"] as? String,
            lensConstruction: dict["lens_construction"] as? String,
            apertureBlades: dict["aperture_blades"] as? String,
            angleOfView: dict["angle_of_view"] as? String,
            mount: dict["mount"] as? String,
            length: dict["length"] as? String,
            weight: dict["weight"] as? String,
            dateUpdated: dict["date_updated"] as? String,
            representativePrice: representativePrice,
            autoCreateImageOnDisk: autoCreateImageOnDisk,
            context: context
        )
    }
    
    func createImageOnDisk() {
        self.imageFileName = FileHelper.createImageOnDisk(self.img)
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