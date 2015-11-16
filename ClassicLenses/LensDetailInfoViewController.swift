//
//  LensDetailInfoViewController.swift
//  ClassicLenses
//
//  Created by Keng Siang Lee on 1/11/15.
//  Copyright © 2015 KSL. All rights reserved.
//

import UIKit

class LensDetailInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //============================================
    // MARK: INSTANCE VARIABLES
    //============================================
    
    //array of dictionaries for name-attribute mapping
    let attrs = [
        ["brand": "brand"],
        ["focal length": "focalLength"],
        ["aperture": "aperture"],
        ["min focus distance": "minFocusDist"],
        ["lens construction": "lensConstruction"],
        ["aperture blades": "apertureBlades"],
        ["angle of view": "angleOfView"],
        ["mount": "mount"],
        ["length": "length"],
        ["weight": "weight"]
    ]
    
    var lens: Lens {
        get {
            let appDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
            return appDelegate.lenses[appDelegate.selectedLensIndex!]
        }
    }
    
    //============================================
    // MARK: IBOUTLETS
    //============================================
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    //============================================
    // MARK: LIFE CYCLE METHODS
    //============================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        CoreDataHelper.sharedContext.performBlockAndWait({
            self.nameLabel.text = self.lens.name
            self.imageView.image = FileHelper.retrieveImage(self.lens.imageFileName)
            self.descriptionLabel.text = self.lens.desc
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //================================================
    // DELEGATE METHODS FOR TABLE
    //================================================
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attrs.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //dequeue a reusable cell
        let cell = tableView.dequeueReusableCellWithIdentifier("LensDetailTableViewCell", forIndexPath: indexPath) as! LensDetailTableViewCell
        
        //get the appropriate attr
        let currAttrDict = attrs[indexPath.row]
        let key = Array(currAttrDict.keys)[0]
        cell.col1Label.text = key.capitalizedString
        CoreDataHelper.sharedContext.performBlockAndWait({
            cell.col2Label.text = self.lens.valueForKey(currAttrDict[key]!) as? String
        })
        
        if indexPath.row % 2 == 0 {
            cell.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        } else {
            cell.backgroundColor = UIColor.whiteColor()
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }

}

//============================================
// MARK: CUSTOM TABLE VIEW CELL
//============================================

class LensDetailTableViewCell: UITableViewCell {
    @IBOutlet weak var col1Label: UILabel!
    @IBOutlet weak var col2Label: UILabel!
}