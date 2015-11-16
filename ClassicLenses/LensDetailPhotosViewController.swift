//
//  LensDetailPhotosViewController.swift
//  ClassicLenses
//
//  Created by Keng Siang Lee on 3/11/15.
//  Copyright © 2015 KSL. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class LensDetailPhotoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    //============================================
    // MARK: CONSTANTS
    //============================================
    
    let NUM_PHOTOS_PER_COLLECTION = 30
    let NUM_LENS_PER_ROW: CGFloat = 3
    let BORDER_SIZE: CGFloat = 2
    
    //============================================
    // MARK: IBOUTLETS
    //============================================
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    //============================================
    // MARK: INSTANCE VARIABLES
    //============================================
    
    var photos = [Photo]()
    var totalPhotosFetched = 0
    
    var lens: Lens {
        get {
            let appDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
            return appDelegate.lenses[appDelegate.selectedLensIndex!]
        }
    }
    
    //============================================
    // MARK: LIFE CYCLE METHODS
    //============================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        CoreDataHelper.sharedContext.performBlockAndWait({
            self.nameLabel.text = self.lens.name
        })
        
        //load photos from core data
        let fetchedPhotos = fetchPhotosFromCoreData()
        if fetchedPhotos.count > 0 {
            //just assign photos variable to the array that has been fetched and refresh view
            photos = fetchedPhotos
            dispatch_async(dispatch_get_main_queue(), {
                self.collectionView.reloadData()
            })
        } else {
            //otherwise, auto download flickr photos
            fetchFlickrPhotos()
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
    
    func fetchPhotosFromCoreData() -> [Photo] {
        
        //prepare fetch request
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "lens==%@", lens)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        //fetch the results
        var results = [AnyObject]()
        CoreDataHelper.sharedContext.performBlockAndWait({
            do {
                results = try CoreDataHelper.sharedContext.executeFetchRequest(fetchRequest)
            } catch {
                UiHelper.showAlertAsync(view: self, title: "Core Data Load Error", msg: "Unable to load photos from Core Data")
            }
        })
        
        return results as! [Photo]
    }
    
    //============================================
    // MARK: IBACTIONS AND CALLBACKS
    //============================================
    
    @IBAction func refreshButtonClicked(sender: UIBarButtonItem) {
        clearAllPhotos()
        collectionView.reloadData()
        fetchFlickrPhotos()
    }
    
    //============================================
    // MARK: METHODS
    //============================================
    
    func clearAllPhotos() {
        
        //clear each photo
        for photo in photos {
            let context = photo.managedObjectContext!
            context.performBlockAndWait({
                
                //remove association with lens
                photo.lens = nil
                
                //delete the object in core data
                context.deleteObject(photo)
            })
        }
        
        //save in core data
        saveChangesToCoreData()
        
        //empty the photos array
        photos.removeAll(keepCapacity: false)
        
    }
    
    func fetchFlickrPhotos() {
        
        //disable new collection button
        refreshButton.enabled = false
        
        //show activity indicator
        dispatch_async(dispatch_get_main_queue(), {
            UiHelper.showActivityIndicator(view: self.view)
        })
        
        var lensName = ""
        CoreDataHelper.sharedContext.performBlockAndWait({
            lensName = self.lens.name!
        })
        
        //perform the api request
        FlickrClient.sharedInstance().fetchPhotosUsingText(
            lensName,
            count: NUM_PHOTOS_PER_COLLECTION,
            totalHandler: { total in
                
                //store total photos
                self.totalPhotosFetched = total
                
                //place in that number of placeholders
                self.clearAllPhotos()
                CoreDataHelper.scratchContext.performBlockAndWait({
                    for _ in 0..<total {
                        self.photos.append(Photo(imageFileName: "loading", context: CoreDataHelper.scratchContext))
                    }
                })
                
                //reload view
                dispatch_async(dispatch_get_main_queue(), {
                    self.collectionView.reloadData()
                })
                
            },
            completionHandler: { completedIndex, errorMsg in
                
                if completedIndex != -1 {
                    
                    //update photo data to use main shared context
                    let flickrClientPhotoAtCompletedIndex = FlickrClient.sharedInstance().photos[completedIndex]
                    var completedImageFileName: String!
                    flickrClientPhotoAtCompletedIndex.managedObjectContext!.performBlockAndWait({
                        completedImageFileName = flickrClientPhotoAtCompletedIndex.imageFileName
                    })
                    CoreDataHelper.sharedContext.performBlockAndWait({
                        self.photos[completedIndex] = Photo(imageFileName: completedImageFileName, context: CoreDataHelper.sharedContext)
                        self.photos[completedIndex].lens = self.lens
                    })
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        //reload specific parts of the collection view with the new data
                        self.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: completedIndex, inSection: 0)])
                    })
                    
                    //do some cleaning up when last photo is fetched
                    if completedIndex == self.totalPhotosFetched - 1 {
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            
                            //hide the activity indicator
                            UiHelper.hideActivityIndicator()
                            
                            //enable refresh button
                            self.refreshButton.enabled = true
                            
                        })
                        
                        //save core data
                        self.saveChangesToCoreData()
                    }
                    
                } else {
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        //hide activity indicator on error
                        UiHelper.hideActivityIndicator()
                        
                        //enable refresh button
                        self.refreshButton.enabled = true
                        
                        //show error msg
                        UiHelper.showAlert(view: self, title: "Flickr request failed", msg: errorMsg)
                        
                    })

                }
            }
        )
    }

    //============================================
    // MARK: COLLECTION VIEW DELEGATE METHODS
    //============================================
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //dequeue a reusable cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("lensDetailPhotoCollectionViewCell", forIndexPath: indexPath) as! LensDetailPhotoCollectionViewCell
        
        //get the photo
        let photo = photos[indexPath.row]
        
        cell.userInteractionEnabled = false
        
        //set appropriate data in the cell
        var photoImageFileName: String?
        photo.managedObjectContext!.performBlockAndWait({
            photoImageFileName = photo.imageFileName
        })
        if let fileName = photoImageFileName {
            
            //if file path is set to "loading", show the loading icon as a placeholder
            if fileName == "loading" {
                cell.imageView.image = UIImage(named: "Loading")
            } else {
                
                //get current documents directory with file name
                let filePath = FileHelper.getDocumentPathForFile(fileName)
                
                if let imageData = NSData(contentsOfURL: NSURL.fileURLWithPath(filePath)) {
                    cell.imageView.image = UIImage(data: imageData)
                    cell.userInteractionEnabled = true
                } else {
                    cell.imageView.image = UIImage(named: "Error")
                }
                
            }
            
        } else {
            cell.imageView.image = UIImage(named: "Error")
        }
        
        //set background to white
        cell.backgroundColor = UIColor.whiteColor()
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        //instantiate a ViewController
        let vc = storyboard?.instantiateViewControllerWithIdentifier("photoViewController") as! PhotoViewController
 
        //pass photo data to the instance
        vc.photo = photos[indexPath.row]

        //show add view controller as a modal
        presentViewController(vc, animated: true, completion: nil)
        
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

class LensDetailPhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
}
