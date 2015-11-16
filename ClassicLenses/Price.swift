//
//  Price.swift
//  ClassicLenses
//
//  Created by Keng Siang Lee on 7/11/15.
//  Copyright © 2015 KSL. All rights reserved.
//

import Foundation
import UIKit
import CoreData

@objc(Price)

class Price: NSManagedObject {
    
    @NSManaged var name: String?
    @NSManaged var site: String?
    @NSManaged var cost: Float
    @NSManaged var thumbnail: String?
    @NSManaged var link: String?
    @NSManaged var status: String?
    @NSManaged var dateUpdated: String?
    @NSManaged var searchTerm: String?
    @NSManaged var imageFileName: String?
    
    @NSManaged var lens: Lens?
    
    //standard core data init method
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(name: String?, site: String?, cost: Float, thumbnail: String?, link: String?, status: String?, dateUpdated: String?, searchTerm: String?, autoCreateImageOnDisk: Bool = true, context: NSManagedObjectContext) {
        
        //add entity to context
        let entity = NSEntityDescription.entityForName("Price", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        //set attributes
        self.name = name
        self.site = site
        self.cost = cost
        self.thumbnail = thumbnail
        self.link = link
        self.status = status
        self.dateUpdated = dateUpdated
        self.searchTerm = searchTerm
        
        if self.thumbnail == "loading" {
            self.imageFileName = "loading"
        } else {
            //create the actual file on disk
            if autoCreateImageOnDisk {
                self.createImageOnDisk()
            }
        }
    }
    
    convenience init(dict: [String: AnyObject], autoCreateImageOnDisk: Bool = true, context: NSManagedObjectContext) {
        self.init(
            name: dict["name"] as? String,
            site: dict["site"] as? String,
            cost: dict["price"] as! Float,
            thumbnail: dict["img"] as? String,
            link: dict["link"] as? String,
            status: dict["status"] as? String,
            dateUpdated: dict["date_updated"] as? String,
            searchTerm: dict["search_term"] as? String,
            autoCreateImageOnDisk: autoCreateImageOnDisk,
            context: context
        )
    }
    
    func createImageOnDisk() {
        self.imageFileName = FileHelper.createImageOnDisk(self.thumbnail)
    }
    
}