//
//  PhotoViewController.swift
//  ClassicLenses
//
//  Created by Keng Siang Lee on 4/11/15.
//  Copyright © 2015 KSL. All rights reserved.
//

import UIKit

class PhotoViewController : UIViewController {
    
    //============================================
    // MARK: INSTANCE VARIABLES
    //============================================
    
    var photo: Photo!
    
    //============================================
    // MARK: IBOUTLETS
    //============================================
    
    @IBOutlet weak var imageView: UIImageView!
    
    //============================================
    // MARK: LIFE CYCLE METHODS
    //============================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //get current documents directory with file name
        var filePath = ""
        photo.managedObjectContext!.performBlockAndWait({
            filePath = FileHelper.getDocumentPathForFile(self.photo.imageFileName!)
        })
        
        if let imageData = NSData(contentsOfURL: NSURL.fileURLWithPath(filePath)) {
            imageView.image = UIImage(data: imageData)
        } else {
            imageView.image = UIImage(named: "Error")
        }
    }
    
    //============================================
    // MARK: IBACTIONS AND CALLBACKS
    //============================================
    
    @IBAction func closeButtonClicked(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}