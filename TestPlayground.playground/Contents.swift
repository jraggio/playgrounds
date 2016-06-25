// Playground to test caching within NSURLSession loading of images comapred to
// method I have used in the past with NSData(fromURL).  I also want to compare loading
// multiple images in an array with some parallelization versus serial as I have done before

// For some reaosn it looks like loadParallelUsingNSData even with 1 concurrent is much faster than loadSerialUsingNSData
// Not clear that the max concurrent controls how many things are pulled off the queue at once, or if the queue actually waits
// for the actions to complete before starting new ones.

// modifed the serial version to call dispatch_async(accessQueue){} when adding items to the array as is done
// in the parrallel verison and it got much faster.  Perhaps this is because it lets the array resize itself in
// a separate thread while the main thread gets the next image?

// this probably also explains why the inserts seem to get slower as the array gets larger?

// if I remove the array.append calls entirely then the serial version is faster, but so is the parallel.

import Cocoa
import CoreFoundation
import Foundation
import XCPlayground

// makes it so async commands work
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true


class ParkBenchTimer {
    
    let startTime:CFAbsoluteTime
    var endTime:CFAbsoluteTime?
    
    init() {
        startTime = CFAbsoluteTimeGetCurrent()
    }
    
    func stop() -> CFAbsoluteTime {
        endTime = CFAbsoluteTimeGetCurrent()
        
        return duration!
    }
    
    var duration:CFAbsoluteTime? {
        if let endTime = endTime {
            return endTime - startTime
        } else {
            return nil
        }
    }
}

public extension NSURLSession {
    
    /// Return data from synchronous URL request
    public static func requestSynchronousData(request: NSURLRequest) -> NSData? {
        var data: NSData? = nil
        let semaphore: dispatch_semaphore_t = dispatch_semaphore_create(0)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {
            taskData, _, error -> () in
            data = taskData
            if data == nil, let error = error {print(error)}
            dispatch_semaphore_signal(semaphore);
        })
        task.resume()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return data
    }
}


let flickrURL = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=5423dbab63f23a62ca4a986e7cbb35e2&per_page=200&tags=pizza&sort=relevance&safe_search=1&media=photos&extras=url_q&format=json&nojsoncallback=1"

//let flickrURL2 = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=5423dbab63f23a62ca4a986e7cbb35e2&per_page=200&tags=tennis&sort=relevance&safe_search=1&media=photos&extras=url_q&format=json&nojsoncallback=1"


private func loadSerialUsingNSData(){
    let timer = ParkBenchTimer()
    print("loadSerialUsingNSData() Called")
    
    var imageArray = [NSImage]()
    let url: NSURL = NSURL(string:flickrURL)!
    
    let accessQueue = dispatch_queue_create("SynchronizedArrayAccess", DISPATCH_QUEUE_SERIAL)
    
    if let jsonData:NSData = NSData(contentsOfURL: url){
        do {
            if let jsonDict = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                if let photoArray = jsonDict["photos"]?["photo"] as? [[String:AnyObject]] {
                    for flickrImageRecord in photoArray {
                        if let imageURL = NSURL(string:flickrImageRecord["url_q"] as! String){
                            if let data = NSData(contentsOfURL: imageURL){
                                let image = NSImage(data: data)!
                                dispatch_async(accessQueue) { imageArray.append(image) }
                                // imageArray.append(image)
                            }
                        }
                    }
                }
            }
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
        }
    }
    
    let s = String(format: "%.4f", timer.stop())
    print("loadSerialUsingNSData took \(s) seconds and resulted in \(imageArray.count) items in the image array.")
    
}

private func loadSerialUsingNSURLSession(){
    let timer = ParkBenchTimer()
    print("loadSerialUsingNSURLSession() Called")
    
    var imageArray = [NSImage]()
    let url: NSURL = NSURL(string:flickrURL)!
    
    let accessQueue = dispatch_queue_create("SynchronizedArrayAccess", DISPATCH_QUEUE_SERIAL)
    
    if let jsonData:NSData = NSData(contentsOfURL: url){
        do {
            if let jsonDict = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                if let photoArray = jsonDict["photos"]?["photo"] as? [[String:AnyObject]] {
                    for flickrImageRecord in photoArray {
                        if let imageURL = NSURL(string:flickrImageRecord["url_q"] as! String){
                            
                            let request = NSURLRequest(URL: imageURL)
                            
                            if let data = NSURLSession.requestSynchronousData(request){
                                let image = NSImage(data: data)!
                                dispatch_async(accessQueue) { imageArray.append(image) }
                                // imageArray.append(image)
                            }
                        }
                    }
                }
            }
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
        }
    }
    
    let s = String(format: "%.4f", timer.stop())
    print("loadSerialUsingNSURLSession took \(s) seconds and resulted in \(imageArray.count) items in the image array.")
    
}


private func loadParallelUsingNSData(){
    let timer = ParkBenchTimer()
    print("loadParallelUsingNSData() Called")
    
    var imageArray = [NSImage]()
    let url: NSURL = NSURL(string:flickrURL)!
    let operationQueue = NSOperationQueue()
    operationQueue.maxConcurrentOperationCount = 8
    
    //print(operationQueue.maxConcurrentOperationCount)
    
    let accessQueue = dispatch_queue_create("SynchronizedArrayAccess", DISPATCH_QUEUE_SERIAL)
    
    if let jsonData:NSData = NSData(contentsOfURL: url){
        do {
            if let jsonDict = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                if let photoArray = jsonDict["photos"]?["photo"] as? [[String:AnyObject]] {
                    for flickrImageRecord in photoArray {
                        // print(flickrImageRecord)
                        let blockOperation = NSBlockOperation()
                        
                        blockOperation.addExecutionBlock {
                            
                            if let imageURL = NSURL(string:flickrImageRecord["url_q"] as! String){
                                // sleep(1)
                                
                                //print(imageURL)
                                if let data = NSData(contentsOfURL: imageURL){
                                    //sleep(1)
                                    let image = NSImage(data: data)!
                                    
                                    dispatch_async(accessQueue) { imageArray.append(image) }
                                }
                            }
                            
                        } // end operation block
                        
                        operationQueue.addOperation(blockOperation)
                    }
                }
            }
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
        }
    }
    
    // blocks the main thread until the queue is empty
    operationQueue.waitUntilAllOperationsAreFinished()
    // print("Queue emptied")
    
    // print the results
    dispatch_async(accessQueue) {
        let s = String(format: "%.4f", timer.stop())
        
        print("loadParallelUsingNSData took \(s) seconds and resulted in \(imageArray.count) items in the image array.")
    }
    
}

private func loadParallelUsingNSURLSession(){
    let timer = ParkBenchTimer()
    print("loadParallelUsingNSURLSession() Called")
    
    var imageArray = [NSImage]()
    let url: NSURL = NSURL(string:flickrURL)!
    let operationQueue = NSOperationQueue()
    operationQueue.maxConcurrentOperationCount = 8
    
    //print(operationQueue.maxConcurrentOperationCount)
    
    let accessQueue = dispatch_queue_create("SynchronizedArrayAccess", DISPATCH_QUEUE_SERIAL)
    
    if let jsonData:NSData = NSData(contentsOfURL: url){
        do {
            if let jsonDict = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                if let photoArray = jsonDict["photos"]?["photo"] as? [[String:AnyObject]] {
                    for flickrImageRecord in photoArray {
                        // print(flickrImageRecord)
                        let blockOperation = NSBlockOperation()
                        
                        blockOperation.addExecutionBlock {
                            
                            if let imageURL = NSURL(string:flickrImageRecord["url_q"] as! String){
                                
                                let request = NSURLRequest(URL: imageURL)
                                
                                if let data = NSURLSession.requestSynchronousData(request){
                                    let image = NSImage(data: data)!
                                    dispatch_async(accessQueue) { imageArray.append(image) }
                                    // imageArray.append(image)
                                }
                                
                                
                            }
                            
                        } // end operation block
                        
                        operationQueue.addOperation(blockOperation)
                    }
                }
            }
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
        }
    }
    
    // blocks the main thread until the queue is empty
    operationQueue.waitUntilAllOperationsAreFinished()
    // print("Queue emptied")
    
    // print the results
    dispatch_async(accessQueue) {
        let s = String(format: "%.4f", timer.stop())
        
        print("loadParallelUsingNSURLSession took \(s) seconds and resulted in \(imageArray.count) items in the image array.")
    }
    
}


private func loadUsingNSURLSessionTask(){
    let timer = ParkBenchTimer()
    print("loadUsingNSURLSessionTask() Called")
    
    var imageArray = [NSImage]()
    let url: NSURL = NSURL(string:flickrURL)!
    // let operationQueue = NSOperationQueue()
    // operationQueue.maxConcurrentOperationCount = 8
    
    //print(operationQueue.maxConcurrentOperationCount)
    
    let accessQueue = dispatch_queue_create("SynchronizedArrayAccess", DISPATCH_QUEUE_SERIAL)
    let downloadGroup = dispatch_group_create()
    
    if let jsonData:NSData = NSData(contentsOfURL: url){
        do {
            if let jsonDict = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                if let photoArray = jsonDict["photos"]?["photo"] as? [[String:AnyObject]] {
                    for flickrImageRecord in photoArray {
                        
                        
                        if let imageURL = NSURL(string:flickrImageRecord["url_q"] as! String){
                            
                            let request = NSURLRequest(URL: imageURL)
                            //print(request.cachePolicy.rawValue)
                            
                            var data: NSData? = nil
                            dispatch_group_enter(downloadGroup)
                            let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {
                                taskData, _, error -> () in
                                data = taskData
                                if data == nil, let error = error {print(error)}
                                dispatch_group_leave(downloadGroup)
                                let image = NSImage(data: data!)
                                //dispatch_async(accessQueue) { imageArray.append(image!) }
                            })
                            task.resume()
                            
                        }
                        
                    }
                }
            }
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
        }
    }
    
    // blocks the main thread until the dispatchgroup is empty
    dispatch_group_wait(downloadGroup, DISPATCH_TIME_FOREVER)
    print("dispatch_group emptied")
    
    // print the results
    dispatch_async(accessQueue) {
        let s = String(format: "%.4f", timer.stop())
        
        print("loadUsingNSURLSessionTask took \(s) seconds and resulted in \(imageArray.count) items in the image array.")
    }
    
}





// Now call the funcitons ;-)
//loadSerialUsingNSData()
//sleep(3)
//loadSerialUsingNSURLSession()
//sleep(3)
//loadParallelUsingNSData()
//sleep(3)
//loadParallelUsingNSURLSession()
//sleep(3)
loadUsingNSURLSessionTask()
