//
//  LensViewController.swift
//  ClassicLenses
//
//  Created by Keng Siang Lee on 1/11/15.
//  Copyright © 2015 KSL. All rights reserved.
//

import UIKit
import CoreData

class LensViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    //============================================
    // MARK: CONSTANTS
    //============================================
    
    let NUM_LENS_PER_ROW: CGFloat = 2
    let BORDER_SIZE: CGFloat = 2
    
    let SCRAPING_HUB_LENS_JOB_ID = "26594"
    let SCRAPING_HUB_PRICE_JOB_ID = "26358"
    
    //============================================
    // MARK: INSTANCE VARIABLES
    //============================================
    
    var appDelegate: AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }
    
    //============================================
    // MARK: IBOUTLETS
    //============================================
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    
    //============================================
    // MARK: LIFE CYCLE METHODS
    //============================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //load prices from core data
        let fetchedPrices = fetchPricesFromCoreData()
        if fetchedPrices.count > 0 {
            
            appDelegate.prices = rearrangePriceArrayIntoDictionary(fetchedPrices)
            
            //load lenses from core data
            let fetchedLenses = self.fetchLensesFromCoreData()
            if fetchedLenses.count > 0 {
                
                self.appDelegate.lenses = fetchedLenses
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    //reload collection view with the data
                    self.collectionView.reloadData()
                    
                    //hide the activity indicator
                    UiHelper.hideActivityIndicator()
                    
                    //enable refresh button
                    self.refreshButton.enabled = true
                })
                
            } else {
                //otherwise download prices
                self.fetchLenses()
            }
            
        } else {
            //otherwise download prices
            fetchPrices()
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    //============================================
    // MARK: CORE DATA METHODS
    //============================================
    
    func saveChangesToCoreData() {
        CoreDataHelper.sharedContext.performBlockAndWait({
            do {
                try CoreDataHelper.sharedContext.save()
            } catch {
                UiHelper.showAlertAsync(view: self, title: "Core Data Save Error", msg: "Unable to save to Core Data")
                return
            }
        })
    }
    
    func fetchPricesFromCoreData() -> [Price] {
        
        //prepare fetch request
        let fetchRequest = NSFetchRequest(entityName: "Price")
        
        //fetch the results
        var results = [AnyObject]()
        CoreDataHelper.sharedContext.performBlockAndWait({
            do {
                results = try CoreDataHelper.sharedContext.executeFetchRequest(fetchRequest)
            } catch {
                UiHelper.showAlertAsync(view: self, title: "Core Data Load Error", msg: "Unable to load prices from Core Data")
            }
        })
        
        return results as! [Price]
    }
    
    func fetchLensesFromCoreData() -> [Lens] {
        
        //prepare fetch request
        let fetchRequest = NSFetchRequest(entityName: "Lens")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        //fetch the results
        var results = [AnyObject]()
        CoreDataHelper.sharedContext.performBlockAndWait({
            do {
                results = try CoreDataHelper.sharedContext.executeFetchRequest(fetchRequest)
            } catch {
                UiHelper.showAlertAsync(view: self, title: "Core Data Load Error", msg: "Unable to load lenses from Core Data")
            }
        })
        
        return results as! [Lens]
    }
    
    //============================================
    // MARK: IBACTIONS AND CALLBACKS
    //============================================
    
    @IBAction func refreshButtonClicked(sender: UIBarButtonItem) {
        
        //clear all data
        clearAllPrices()
        clearAllLenses()
        
        //refresh view
        collectionView.reloadData()
        
        //start download
        fetchPrices()
        
    }
    
    //============================================
    // MARK: METHODS
    //============================================
    
    func rearrangePriceArrayIntoDictionary(prices: [Price]) -> [String: [String: [Price]]] {
        
        var rearrangedPrices = [String: [String: [Price]]]()
        
        for price in prices {
            
            CoreDataHelper.sharedContext.performBlockAndWait({
            
                if let searchTerm = price.searchTerm {
                   
                    //create searchTerm dictionary if doesn't exist
                    if rearrangedPrices[searchTerm] == nil {
                        rearrangedPrices[searchTerm] = [String: [Price]]()
                    }
                    
                    if let site = price.site {
                        
                        //create site dictionary if doesn't exist
                        if rearrangedPrices[searchTerm]![site] == nil {
                            rearrangedPrices[searchTerm]![site] = [Price]()
                        }
                        
                        rearrangedPrices[searchTerm]![site]!.append(price)
                        
                    }
                    
                }
                
            })
        }
        
        return rearrangedPrices
        
    }
    
    func clearAllPrices() {
        
        //delete core data objects
        for siteDict in self.appDelegate.prices.values {
            for prices in siteDict.values {
                for price in prices {
                    let context = price.managedObjectContext!
                    context.performBlockAndWait({
                        price.lens = nil
                        context.deleteObject(price)
                    })
                }
            }
        }
        
        //clear prices array
        appDelegate.prices.removeAll()
        
        //save to core data
        saveChangesToCoreData()
    }
    
    func filterLatestOfEachPrice(items: [AnyObject]) -> [Price] {
        
        var prices = [Price]()
        
        //dictionary of search term -> dictionary of sites -> dictionary of item names -> array of items
        var tempPricesDict = [String: [String: [String: [AnyObject]]]]()
        
        //throw each item into their respective bins
        for item in items {
            
            if let searchTerm = item["search_term"] as? String {
                
                //create searchTerm dictionary if doesn't exist
                if tempPricesDict[searchTerm] == nil {
                    tempPricesDict[searchTerm] = [String: [String: [AnyObject]]]()
                }
                
                if let site = item["site"] as? String {
                    
                    //create site dictionary if doesn't exist
                    if tempPricesDict[searchTerm]![site] == nil {
                        tempPricesDict[searchTerm]![site] = [String: [AnyObject]]()
                    }
                    
                    if let name = item["name"] as? String {
                        if name != "" {
                            
                            //create site dictionary if doesn't exist
                            if tempPricesDict[searchTerm]![site]![name] == nil {
                                tempPricesDict[searchTerm]![site]![name] = [AnyObject]()
                            }
                            
                            if let price = item["price"] as? Float {
                                if price != 0 {
                                    tempPricesDict[searchTerm]![site]![name]!.append(item)
                                }
                            }
                            
                        }
                    }
                    
                }
                
            }
        }
        
        //within each bin, get the latest item and add it into our prices array
        for tempPricesSites in tempPricesDict.values {
            for tempPricesNames in tempPricesSites.values {
                for tempPrices in tempPricesNames.values {
                    
                    if tempPrices.count > 0 {
                        
                        //sort
                        let tempPricesSorted = tempPrices.sort { $0.valueForKey("date_updated") as! String > $1.valueForKey("date_updated") as! String }
                        
                        //get first item from sorted list and add to actual list
                        CoreDataHelper.sharedContext.performBlockAndWait({
                            let price = Price(dict: tempPricesSorted[0] as! [String : AnyObject], autoCreateImageOnDisk: false, context: CoreDataHelper.sharedContext)
                            prices.append(price)
                        })
                    }
                    
                }
                
            }
        }
        
        return prices
    }
    
    func fetchPrices() {
        
        //show activity indicator
        dispatch_async(dispatch_get_main_queue(), {
            
            //disable refresh button
            self.refreshButton.enabled = false
            
            //show activity indicator
            UiHelper.showActivityIndicator(view: self.view)
            
        })
        
        //download prices
        ScrapingHubClient.sharedInstance().fetchItemsForJob(SCRAPING_HUB_PRICE_JOB_ID,
            completionHandler: { success, errorMsg in
                
                if success {
                    
                    self.clearAllPrices()
                    
                    //scraping hub returns multiple items per price (with diff timestamps) unfortunately and we have to grab the latest on our own
                    let filteredPrices: [Price] = self.filterLatestOfEachPrice(ScrapingHubClient.sharedInstance().items)
                   
                    //rearrange the prices as a dictionary of arrays
                    self.appDelegate.prices = self.rearrangePriceArrayIntoDictionary(filteredPrices)

                    //load lenses from core data
                    let fetchedLenses = self.fetchLensesFromCoreData()
                    if fetchedLenses.count > 0 {
                        
                        self.appDelegate.lenses = fetchedLenses
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            
                            //reload collection view with the data
                            self.collectionView.reloadData()
                            
                            //hide the activity indicator
                            UiHelper.hideActivityIndicator()
                            
                            //enable refresh button
                            self.refreshButton.enabled = true
                        })
                        
                    } else {
                        //otherwise download prices
                        self.fetchLenses()
                    }
                    
                } else {
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        //hide activity indicator on error
                        UiHelper.hideActivityIndicator()
                        
                        //enable refresh button
                        self.refreshButton.enabled = true
                        
                        //show error msg
                        UiHelper.showAlert(view: self, title: "Prices request failed", msg: errorMsg)
                        
                    })
                }
                
            }
        )
        
    }
    
    func clearAllLenses() {
        
        //delete core data objects
        for lens in appDelegate.lenses {
            let context = lens.managedObjectContext!
            context.performBlockAndWait({
                context.deleteObject(lens)
            })
        }
        
        //clear lenses array
        appDelegate.lenses.removeAll()
        
        //save to core data
        saveChangesToCoreData()
    }
    
    func filterLatestOfEachLens(items: [AnyObject]) -> [Lens] {
        
        var lenses = [Lens]()
        
        //create a dictionary which uses the name of the lens to index into a list of item
        var tempLensDict = [String: [AnyObject]]()
        
        //throw each item into their respective name-bins
        for item in items {
            if let name = item["name"] as? String {
                
                //create name dictionary if doesn't exist
                if tempLensDict[name] == nil {
                    tempLensDict[name] = [Lens]()
                }
                
                tempLensDict[name]!.append(item)
            }
        }
        
        //within each bin, get the latest item
        for tempLenses in tempLensDict.values {
            
            //sort
            let tempLensesSorted = tempLenses.sort { $0["date_updated"] as! String > $1["date_updated"] as! String }
            
            //get first item from sorted list and add to actual list
            CoreDataHelper.sharedContext.performBlockAndWait({
                let lens = Lens(dict: tempLensesSorted[0] as! [String : AnyObject], autoCreateImageOnDisk: false, context: CoreDataHelper.sharedContext)
                lenses.append(lens)
            })
        }
        
        //finally, sort the array for ordered retrieval based on name
        CoreDataHelper.sharedContext.performBlockAndWait({
            lenses.sortInPlace { $0.name < $1.name }
        })
        
        return lenses
    }
    
    func fetchLenses() {
        
        dispatch_async(dispatch_get_main_queue(), {
            
            //disable refresh button
            self.refreshButton.enabled = false
            
            //show activity indicator
            UiHelper.showActivityIndicator(view: self.view)
        })
        
        ScrapingHubClient.sharedInstance().fetchItemsForJob(SCRAPING_HUB_LENS_JOB_ID,
            completionHandler: { success, errorMsg in

                if success {

                    //scraping hub returns multiple items per lens (with diff timestamps) unfortunately and we have to grab the latest on our own
                    let filteredLenses: [Lens] = self.filterLatestOfEachLens(ScrapingHubClient.sharedInstance().items)
                    let total = filteredLenses.count
                    
                    self.clearAllLenses()
                    
                    //place in placeholders
                    CoreDataHelper.scratchContext.performBlockAndWait({
                        for _ in 0..<total {
                            let placeholderLens = Lens(dict: ["img": "loading"], context: CoreDataHelper.scratchContext)
                            self.appDelegate.lenses.append(placeholderLens)
                        }
                    })
                    
                    //reload view to show the loading cells
                    dispatch_async(dispatch_get_main_queue(), {
                        self.collectionView.reloadData()
                    })

                    //update the cells one by one as we save the images on disk
                    for (index, filteredLens) in filteredLenses.enumerate() {
                        
                        //create the actual image on disk (this part takes a while and is worth reloading cells one by one to show progress)
                        CoreDataHelper.sharedContext.performBlockAndWait({
                            filteredLens.createImageOnDisk()
                        })
                        
                        self.appDelegate.lenses[index] = filteredLens
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            //reload specific parts of the collection view with the new data
                            self.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)])
                        })
                    }
                    
                    //update all prices to point to their respective lenses (now that they have been downloaded)
                    CoreDataHelper.sharedContext.performBlockAndWait({
                        for (searchTerm, siteDict) in self.appDelegate.prices {
                            for prices in siteDict.values {
                                for price in prices {
                                    //find the lens that matches the search term
                                    for lens in self.appDelegate.lenses {
                                        if lens.name! == searchTerm {
                                            price.lens = lens
                                        }
                                    }
                                }
                            }
                        }
                    })
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        //hide the activity indicator
                        UiHelper.hideActivityIndicator()
                        
                        //enable refresh button
                        self.refreshButton.enabled = true
                        
                    })
                    
                    //save core data
                    self.saveChangesToCoreData()
                    
                } else {
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        //hide activity indicator on error
                        UiHelper.hideActivityIndicator()
                        
                        //enable refresh button
                        self.refreshButton.enabled = true
                        
                        //show error msg
                        UiHelper.showAlert(view: self, title: "Lenses request failed", msg: errorMsg)
                        
                    })

                }
                
            }
        )
        
    }
    
    //============================================
    // MARK: COLLECTION VIEW DELEGATE METHODS
    //============================================
    
    func getRepresentativePriceOfLens(lens: Lens) -> Float? {
        
        if let lensname = lens.name {
            if let pricesSiteDict = appDelegate.prices[lensname] {
                if let pricesForLens = pricesSiteDict["B&H (bhphotovideo.com)"] {  //using B&H prices as the representative price
                    
                    //sort
                    let pricesForLensSorted = pricesForLens.sort { $0.valueForKey("cost") as! Float > $1.valueForKey("cost") as! Float }
                    
                    //get first item from sorted list and add to actual list
                    if pricesForLensSorted.count > 0 {
                        return pricesForLensSorted[0].cost
                    }
                }
            }
        }
        
        return nil

    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return appDelegate.lenses.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //dequeue a reusable cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("lensCollectionViewCell", forIndexPath: indexPath) as! LensCollectionViewCell
        
        //get the lens
        let lens = appDelegate.lenses[indexPath.row]
        
        //set appropriate data in the cell
        lens.managedObjectContext!.performBlockAndWait({
            if let lensName = lens.name {
                cell.nameLabel.text = lensName
            } else {
                cell.nameLabel.text = ""
            }
            if let price = self.getRepresentativePriceOfLens(lens) {
                cell.priceLabel.text = String(format: "$%.2f", price)
            } else {
                cell.priceLabel.text = "-"
            }
            
            cell.imageView.image = FileHelper.retrieveImage(lens.imageFileName)
            cell.userInteractionEnabled = lens.imageFileName != "loading" && lens.imageFileName != "error"
        })
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        //instantiate a ViewControllers
        let tabvc = storyboard!.instantiateViewControllerWithIdentifier("LensDetailTabBarController") as! LensDetailTabBarController

        //store a global index to selected lens
        appDelegate.selectedLensIndex = indexPath.row
        
        //push view controller onto navigation stack
        navigationController!.pushViewController(tabvc, animated: true)
        
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let size = (collectionView.bounds.size.width - (NUM_LENS_PER_ROW + 1) * BORDER_SIZE) / NUM_LENS_PER_ROW
        return CGSize(width: size, height: size)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: BORDER_SIZE, left: BORDER_SIZE, bottom: BORDER_SIZE, right: BORDER_SIZE)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return BORDER_SIZE
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return BORDER_SIZE
    }
}

//============================================
// MARK: CUSTOM COLLECTION VIEW CELL
//============================================

class LensCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
}
