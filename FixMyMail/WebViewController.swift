//
//  WebViewController.swift
//  FixMyMail
//
//  Created by Moritz Müller on 31.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import CoreImage
import ImageIO
import CoreData

class WebViewController: UIViewController, MCOMessageViewDelegate {
    var messageView: MCOMessageView!
    var storage: NSMutableDictionary = NSMutableDictionary()
    var ops: NSMutableArray = NSMutableArray()
    var pending: NSMutableSet = NSMutableSet()
    var callbacks: NSMutableDictionary = NSMutableDictionary()
    var message: Email!
    var session: MCOIMAPSession!
    
    override func viewDidLoad() {
        messageView = MCOMessageView(frame: self.view.bounds)
        messageView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        self.view.addSubview(messageView)
        var parser: MCOMessageParser = MCOMessageParser(data: message.data)
        messageView.message = parser
        messageView.folder = "INBOX"
        messageView.delegate = self
    }
    
    func putMessage() {
        for op in ops {
            op.cancel()
        }
        ops.removeAllObjects()
        callbacks.removeAllObjects()
        storage.removeAllObjects()
        pending.removeAllObjects()
    }
    
    func fetchIMAPPartWithUniqueID(partUniqueID: String, folder: String) -> MCOIMAPFetchContentOperation? {
        if pending.containsObject(partUniqueID) {
            return nil
        }
        var part: MCOIMAPPart = (message.mcomessage as! MCOIMAPMessage).partForUniqueID(partUniqueID) as! MCOIMAPPart
        pending.addObject(partUniqueID)
        var op: MCOIMAPFetchContentOperation = session.fetchMessageAttachmentOperationWithFolder(folder, uid: (message.mcomessage as! MCOIMAPMessage).uid, partID: part.partID, encoding: part.encoding)
        ops.addObject(op)
        op.start {(error, data) -> Void in
            if error.code != MCOErrorCode.None.rawValue {
                self.callbackForPartUniqueID(partUniqueID, error: error)
                return
            }
            self.ops.removeObject(op)
            self.storage.setObject(data, forKey: partUniqueID)
            self.pending.removeObject(partUniqueID)
            self.callbackForPartUniqueID(partUniqueID, error: nil)
        }
        return op
    }
    
    typealias DownloadCallback = (error: NSError?) -> Void
    
    func callbackForPartUniqueID(partUniqueID: String, error: NSError?) {
        var blocks: NSArray = callbacks.objectForKey(partUniqueID) as! NSArray
        for block in blocks {
            (block as! DownloadCallback)(error: error)
        }
    }
    
    func MCOMessageView_templateForAttachment(view: MCOMessageView!) -> String! {
        return "<div style=\"padding-bottom: 20px; font-family: Helvetica; font-size: 13px;\">{{HEADER}}</div><div>{{BODY}}</div>"
    }
    
    func messageView(view: MCOMessageView!, canPreviewPart part: MCOAbstractPart!) -> Bool {
        var mimeType: String = part.mimeType.lowercaseString
        if mimeType == "image/tiff" {
            return true
        }
        if mimeType == "image/tif" {
            return true
        }
        if mimeType == "image/pdf" {
            return true
        }
        var pathExtension: String? = nil
        if part.filename != nil {
            pathExtension = part.filename.pathExtension.lowercaseString
        }
        if let ext = pathExtension {
            if ext == "tiff" {
                return true
            }
            if ext == "tif" {
                return true
            }
            if ext == "pdf" {
                return true
            }
        }
        return false
    }
    
    func messageView(view: MCOMessageView!, filteredHTMLForMessage html: String!) -> String! {
        return html
    }
    
    func messageView(view: MCOMessageView!, filteredHTMLForPart html: String!) -> String! {
        return html
    }
    
    func messageView(view: MCOMessageView!, dataForPartWithUniqueID partUniqueID: String!) -> NSData! {
        var attachement: MCOAttachment = self.messageView.message.partForUniqueID(partUniqueID) as! MCOAttachment
        return attachement.data
    }
    
    func messageView(view: MCOMessageView!, fetchDataForPartWithUniqueID partUniqueID: String!, downloadedFinished downloadFinished: ((NSError!) -> Void)!) {
        var op: MCOIMAPFetchContentOperation? = self.fetchIMAPPartWithUniqueID(partUniqueID, folder: "INBOX")
        if op != nil {
            self.ops.addObject(op!)
        }
        if downloadFinished != nil {
            var blocks: NSMutableArray? = self.callbacks.objectForKey(partUniqueID) as? NSMutableArray
            if blocks == nil {
                blocks = NSMutableArray()
                self.callbacks.setObject(blocks!, forKey: partUniqueID)
            }
            blocks?.addObject(downloadFinished as! AnyObject)
        }
    }
    
    func messageView(view: MCOMessageView!, previewForData data: NSData!, isHTMLInlineImage: Bool) -> NSData! {
        if isHTMLInlineImage {
            return data
        } else {
            return self.convertToJPEGData(data)
        }
    }
    
    let IMAGE_PREVIEW_HEIGHT = 300
    let IMAGE_PREVIEW_WIDTH = 500
    
    func convertToJPEGData(data: NSData) -> NSData? {
        var imageSource: CGImageSourceRef?
        var thumbnail: CGImageRef
        var info: NSMutableDictionary = NSMutableDictionary()
        let width = IMAGE_PREVIEW_WIDTH
        let height = IMAGE_PREVIEW_HEIGHT
        let quality: float_t = 1.0
        
        imageSource = CGImageSourceCreateWithData(data, nil)
        if imageSource == nil {
            return nil
        }
        info.setObject(kCFBooleanTrue as AnyObject, forKey: kCGImageSourceCreateThumbnailWithTransform as String)
        info.setObject(kCFBooleanTrue as AnyObject, forKey: kCGImageSourceCreateThumbnailFromImageAlways as String)
        info.setObject(NSNumber(float: Float(IMAGE_PREVIEW_WIDTH)), forKey: kCGImageSourceThumbnailMaxPixelSize as String)
        thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource!, 0, info)
        var destination: CGImageDestinationRef
        var destData: NSMutableData = NSMutableData(data: data)
        destination = CGImageDestinationCreateWithData(destData, "public.jpeg" as CFStringRef, 1, nil)
        CGImageDestinationAddImage(destination, thumbnail, nil)
        CGImageDestinationFinalize(destination)
        
        return destData
    }
    
}
