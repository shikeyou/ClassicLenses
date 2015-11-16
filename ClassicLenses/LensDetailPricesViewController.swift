//
//  LensDetailPricesViewController.swift
//  ClassicLenses
//
//  Created by Keng Siang Lee on 7/11/15.
//  Copyright © 2015 KSL. All rights reserved.
//

import UIKit

class LensDetailPricesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //============================================
    // MARK: INSTANCE VARIABLES
    //============================================
    
    var lens: Lens {
        get {
            let appDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
            return appDelegate.lenses[appDelegate.selectedLensIndex!]
        }
    }
    
    var prices: [String: [String: [Price]]] {
        get {
            let appDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
            return appDelegate.prices
        }
    }
    
    //============================================
    // MARK: IBOUTLETS
    //============================================
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!

    //============================================
    // MARK: LIFE CYCLE METHODS
    //============================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        CoreDataHelper.sharedContext.performBlockAndWait({
            self.nameLabel.text = self.lens.name
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //============================================
    // MARK: METHODS
    //============================================
    
    //from http://stackoverflow.com/questions/24723431/swift-days-between-two-nsdates
    func daysBetweenDate(startDate startDate: NSDate, endDate: NSDate) -> Int
    {
        let calendar = NSCalendar.currentCalendar()
        
        let components = calendar.components([.Day], fromDate: startDate, toDate: endDate, options: [])
        
        return components.day
    }
    
    func getDateFromTimeString(dateString: String) -> NSDate? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
        return dateFormatter.dateFromString(dateString)
    }
    
    //================================================
    // DELEGATE METHODS FOR TABLE
    //================================================
    
    func getLastUpdatedStringForPrice(price: Price) -> String {
        
        var lastUpdatedDate: String? = nil
        var numDaysAgo = 0
        var plural = ""
        
        CoreDataHelper.sharedContext.performBlockAndWait({
            if let updated = price.dateUpdated {
                
                if let nsdate = self.getDateFromTimeString(updated) {
                    
                    //retrieve year/month/day
                    let formatter = NSDateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    lastUpdatedDate = formatter.stringFromDate(nsdate)
                    
                    //calculate interval
                    numDaysAgo = self.daysBetweenDate(startDate: nsdate, endDate: NSDate());
                    plural = numDaysAgo == 1 ? "" : "s"
                }
                
            }
        })
        
        if let lud = lastUpdatedDate {
            return "Updated: \(lud) (\(numDaysAgo) day\(plural) ago)"
        } else {
            return "Updated: -"
        }
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var value = 0
        CoreDataHelper.sharedContext.performBlockAndWait({
            if let p = self.prices[self.lens.name!] {
                if section < Array(p.keys).count {
                    value = p[Array(p.keys)[section]]!.count
                }
            }
        })
        return value
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //dequeue a reusable cell
        let cell = tableView.dequeueReusableCellWithIdentifier("LensDetailPricesTableViewCell", forIndexPath: indexPath) as! LensDetailPricesTableViewCell
        
        //get the appropriate attr
        CoreDataHelper.sharedContext.performBlockAndWait({
            if let p = self.prices[self.lens.name!] {
                if indexPath.section < Array(p.keys).count {
                    
                    let priceArray = p[Array(p.keys)[indexPath.section]]!
                    let price = priceArray[indexPath.row]

                    cell.nameLabel.text = price.name
                    
                    cell.lastUpdatedLabel.text = self.getLastUpdatedStringForPrice(price)
                    
                    cell.priceLabel.text = String(format: "$%.2f", price.cost)
                }
                
            }
        })
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var value = 0
        CoreDataHelper.sharedContext.performBlockAndWait({
            if let p = self.prices[self.lens.name!] {
                value = p.count
            }
        })
        return value
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var value = ""
        CoreDataHelper.sharedContext.performBlockAndWait({
            if let p = self.prices[self.lens.name!] {
                if section < Array(p.keys).count {
                    value = "\(Array(p.keys)[section])"
                }
            }
        })
        return value
    }
    
}

//============================================
// MARK: CUSTOM TABLE VIEW CELL
//============================================

class LensDetailPricesTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var lastUpdatedLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
}