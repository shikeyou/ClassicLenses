//
//  ScrapingHubClient.swift
//  ClassicLenses
//
//  Created by Keng Siang Lee on 7/11/15.
//  Copyright © 2015 KSL. All rights reserved.
//

import Foundation

class ScrapingHubClient: NSObject {

    //constants for flickr photos search
    let BASE_URL = "https://storage.scrapinghub.com/items/"
    let API_KEY = "40f0278262364917bf967866088a3094"
    
    //variables for storing parsed data
    var items = [[String: AnyObject]]()
    
    //singleton class function
    class func sharedInstance() -> ScrapingHubClient {
        struct Singleton {
            static var sharedInstance = ScrapingHubClient()
        }
        return Singleton.sharedInstance
    }
    
    func fetchItemsForJob(jobId: String, completionHandler: (success: Bool, errorMsg: String)->Void) {
        let url = "\(BASE_URL)\(jobId)?apikey=\(API_KEY)&format=json"
        HttpHelper.makeHttpRequest(
            requestUrl: url,
            requestMethod: "GET",
            requestDataHandler: { data, response, error in
                
                //check for request error
                if error != nil {
                    completionHandler(success: false, errorMsg: error!.localizedDescription)
                    return
                }
                
                //parse json data
                let (jsonData, jsonParseError) = HttpHelper.parseJsonDataAsArray(data!)
                if jsonParseError != nil {
                    completionHandler(success: false, errorMsg: jsonParseError!.localizedDescription)
                    return
                }
                
                self.items.removeAll()
                for data in jsonData {
                    self.items.append(data as! [String : AnyObject])
                }
                
                completionHandler(success: true, errorMsg: "")
                
            }
        )
    }
    
}