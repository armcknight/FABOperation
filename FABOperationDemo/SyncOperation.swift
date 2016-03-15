//
//  SyncOperation.swift
//  FABOperationDemo
//
//  Created by Andrew McKnight on 3/15/16.
//  Copyright © 2016 Twitter. All rights reserved.
//

import Cocoa

class SyncOperation: NSOperation {
    var delegate: OperationStateChangeDelegate!
    var url: String
    var imageView: NSImageView
    var session: NSURLSession!
    var downloadTask: NSURLSessionDownloadTask!
    var color: NSColor

    init(url: String, imageView: NSImageView, color: NSColor, delegate: OperationStateChangeDelegate, name: String) {
        self.url = url
        self.imageView = imageView
        self.color = color
        self.delegate = delegate

        super.init()

        self.name = name

        self.completionBlock = {
            self.delegate.operationSyncCompletionCalled(self)
        }
    }

    override func main() {
        self.delegate.operationBeganExecuting(self)

        requestWithCompletion() { location, response, error in
            self.session.invalidateAndCancel()
            if (response as! NSHTTPURLResponse).statusCode != 200 || error != nil {
                self.delegate.operationAsyncWorkFailed(self)
            } else {
                if let path = location?.path, data = NSData(contentsOfFile: path) {
                    self.imageView.image = NSImage(data: data)
                }
                self.delegate.operationAsyncWorkFinished(self)
            }
        }

        self.delegate.operationMainMethodFinished(self)
    }

    func requestWithCompletion(completion: (NSURL?, NSURLResponse?, NSError?) -> Void) {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: config, delegate: nil, delegateQueue: NSOperationQueue.mainQueue())
        let request = NSURLRequest(URL: NSURL(string: self.url.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()))!)
        downloadTask = session.downloadTaskWithRequest(request, completionHandler: completion)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) * Int64(rand() % 3 + 1)), dispatch_get_main_queue()) {
            self.downloadTask.resume()
        }
    }

    override func cancel() {
        if downloadTask != nil {
            downloadTask.cancel()
        }
        if session != nil {
            session.invalidateAndCancel()
        }
        self.delegate.operationAsyncWorkCanceled(self)
        super.cancel()
    }
}
