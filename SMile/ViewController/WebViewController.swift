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

class WebViewController: UIViewController, UIActionSheetDelegate, MCOMessageViewDelegate {
    var messageView: MCOMessageView!
    var storage: NSMutableDictionary = NSMutableDictionary()
    var ops: NSMutableArray = NSMutableArray()
    var pending: NSMutableSet = NSMutableSet()
    var callbacks: NSMutableDictionary = NSMutableDictionary()
    var message: Email!
    var session: MCOIMAPSession!
    
    override func viewDidLoad() {
        messageView = MCOMessageView(frame: self.view.bounds)
        messageView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        self.view.addSubview(messageView)
        var parser: MCOMessageParser = MCOMessageParser(data: message.data)
        messageView.message = parser
        messageView.folder = "INBOX"
        messageView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        var buttonDelete = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "delete")
        var buttonReply = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Reply, target: self, action: "replyButtonPressed")
        var buttonCompose = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Compose, target: self, action: "compose")
        var items = [buttonDelete, UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil), buttonReply,UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil), buttonCompose]
        self.navigationController?.visibleViewController.setToolbarItems(items, animated: animated)
        self.navigationController?.setToolbarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: false)
    }
    
    func delete() {        
        //get trashFolderName
        let fetchFoldersOp = session.fetchAllFoldersOperation()
        var folders = [MCOIMAPFolder]()
        fetchFoldersOp.start({ (error, folders) -> Void in
            var trashFolderName: String?
            for folder in folders {
                if ((folder as! MCOIMAPFolder).flags.intersect(MCOIMAPFolderFlag.Trash)) == MCOIMAPFolderFlag.Trash {
                    trashFolderName = (folder as! MCOIMAPFolder).path
                    //NSLog("found it" + self.trashFolderName!)
                    break
                }
            }
            if trashFolderName != nil {
                //copy email to trash folder
                let localCopyMessageOperation = self.session.copyMessagesOperationWithFolder("INBOX", uids: MCOIndexSet(index: UInt64((self.message.mcomessage as! MCOIMAPMessage).uid)), destFolder: trashFolderName)
                
                localCopyMessageOperation.start {(error, uidMapping) -> Void in
                    if let error = error {
                        NSLog("error in deleting email : \(error.userInfo)")
                    }
                }
                
                //set deleteFlag
                let setDeleteFlagOP = self.session.storeFlagsOperationWithFolder("INBOX", uids: MCOIndexSet(index: UInt64((self.message.mcomessage as! MCOIMAPMessage).uid)), kind: MCOIMAPStoreFlagsRequestKind.Add, flags: MCOMessageFlag.Deleted)
                
                setDeleteFlagOP.start({ (error) -> Void in
                    if let error = error {
                        NSLog("error in deleting email (flags) : \(error.userInfo)")
                    } else {
                        NSLog("email deleted")
                        
                        let expangeFolder = self.session.expungeOperation("INBOX")
                        expangeFolder.start({ (error) -> Void in })
                    }
                })
                
                var managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext as NSManagedObjectContext!
                managedObjectContext.deleteObject(self.message)
                
                var error: NSError? = nil
                do {
                    try managedObjectContext.save()
                } catch var error1 as NSError {
                    error = error1
                } catch {
                    fatalError()
                }
                if error != nil {
                    NSLog("%@", error!.description)
                }
            } else {
                NSLog("error: trashFolderName == nil")
            }
        })
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        let replyAll: Bool = !((self.message.mcomessage as! MCOIMAPMessage).header.cc == nil &&
                             (self.message.mcomessage as! MCOIMAPMessage).header.bcc == nil)
        switch buttonIndex {
        case 1:
            self.reply(false)
        case 2:
            if replyAll {
                self.reply(true)
            } else {
                self.forward()
            }
        case 3:
            if replyAll {
                self.forward()
            }
        default:
            return
        }
    }
    
    func replyButtonPressed() {
        if (self.message.mcomessage as! MCOIMAPMessage).header.cc == nil &&
           (self.message.mcomessage as! MCOIMAPMessage).header.bcc == nil {
                let replyActionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Reply", "Forward")
                replyActionSheet.showInView(self.view)
        } else {
            let replyActionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Reply", "Reply all", "Forward")
            replyActionSheet.showInView(self.view)
        }
    }
    
    func reply(replyAll: Bool) {
        let sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
        if replyAll {
            sendView.tableViewIsExpanded = true
            var array: [MCOAddress] = [MCOAddress]()
            let recipients = (self.message.mcomessage as! MCOIMAPMessage).header.to
            for recipient in recipients {
                if (recipient as! MCOAddress).mailbox != self.message.toAccount.emailAddress {
                    array.append(recipient as! MCOAddress)
                }
            }
            let ccRecipients = (self.message.mcomessage as! MCOIMAPMessage).header.cc
            if ccRecipients != nil {
                for ccRecipient in ccRecipients {
                    array.append(ccRecipient as! MCOAddress)
                }
            }
            if array.count == 0 {
                sendView.tableViewIsExpanded = false
            } else {
                sendView.ccRecipients.addObjectsFromArray(array)
            }
        }
        sendView.recipients.addObject((self.message.mcomessage as! MCOIMAPMessage).header.from)
        sendView.account = self.message.toAccount
        sendView.subject = "Re: " + (self.message.mcomessage as! MCOIMAPMessage).header.subject
        let parser = MCOMessageParser(data: self.message.data)
        let date = (self.message.mcomessage as! MCOIMAPMessage).header.date
        sendView.textBody = "On \(date.day()) \(date.month()) \(date.year()), at \(date.hour()):\(date.minute()), " + (self.message.mcomessage as! MCOIMAPMessage).header.from.displayName + " wrote:\n" + parser.plainTextBodyRenderingAndStripWhitespace(false)
        self.navigationController?.pushViewController(sendView, animated: true)
    }
    
    func forward() {
        let sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
        sendView.account = self.message.toAccount
        sendView.subject = "Fwd: " + (self.message.mcomessage as! MCOIMAPMessage).header.subject
        let parser = MCOMessageParser(data: self.message.data)
        sendView.textBody = "\n\nBegin forwarded message:\n" + parser.plainTextBodyRenderingAndStripWhitespace(false)
        self.navigationController?.pushViewController(sendView, animated: true)
    }
    
    func compose() {
        let sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
        sendView.account = self.message.toAccount
        self.navigationController?.pushViewController(sendView, animated: true)
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
        let part: MCOIMAPPart = (message.mcomessage as! MCOIMAPMessage).partForUniqueID(partUniqueID) as! MCOIMAPPart
        pending.addObject(partUniqueID)
        let op: MCOIMAPFetchContentOperation = session.fetchMessageAttachmentOperationWithFolder(folder, uid: (message.mcomessage as! MCOIMAPMessage).uid, partID: part.partID, encoding: part.encoding)
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
        let blocks: NSArray = callbacks.objectForKey(partUniqueID) as! NSArray
        for block in blocks {
            (block as! DownloadCallback)(error: error)
        }
    }
    
    func MCOMessageView_templateForAttachment(view: MCOMessageView!) -> String! {
        return "<div style=\"padding-bottom: 20px; font-family: Helvetica; font-size: 13px;\">{{HEADER}}</div><div>{{BODY}}</div>"
    }
    
    func messageView(view: MCOMessageView!, canPreviewPart part: MCOAbstractPart!) -> Bool {
        let mimeType: String = part.mimeType.lowercaseString
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
        let attachement: MCOAttachment = self.messageView.message.partForUniqueID(partUniqueID) as! MCOAttachment
        return attachement.data
    }
    
    func messageView(view: MCOMessageView!, fetchDataForPartWithUniqueID partUniqueID: String!, downloadedFinished downloadFinished: ((NSError!) -> Void)!) {
        let op: MCOIMAPFetchContentOperation? = self.fetchIMAPPartWithUniqueID(partUniqueID, folder: "INBOX")
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
