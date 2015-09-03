//
//  AttachmentsViewController.swift
//  SMile
//
//  Created by Moritz Müller on 01.09.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import Foundation
import UIKit
import AssetsLibrary

class AttachmentsViewController : UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate {
    
    // MARK: - Initialisation
    @IBOutlet var attachmentsTableView: UITableView!
    
    var attachments: NSMutableDictionary = NSMutableDictionary()
    var keys: [String] = [String]()
    var images: [UIImage] = [UIImage]()
    
    var createdFiles: [NSURL] = [NSURL]()
    
    var isSendAttachment = false
    var isViewAttachment = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Attachments"
        
        self.attachmentsTableView.registerNib(UINib(nibName: "AttachmentCell", bundle: nil), forCellReuseIdentifier: "AttachmentCell")
        
        if self.isSendAttachment {
            var buttonImagePicker: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "pushImagePickerViewWithSender:")
            self.navigationItem.rightBarButtonItem = buttonImagePicker
        }
        if self.isViewAttachment {
            var buttonBack: UIBarButtonItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Plain, target: self, action: "backToRootView:")
            self.navigationItem.leftBarButtonItem = buttonBack
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        if let fileName = (UIApplication.sharedApplication().delegate as! AppDelegate).fileName {
            if let data = (UIApplication.sharedApplication().delegate as! AppDelegate).fileData {
                if self.isSendAttachment {
                    self.attachFile(fileName, data: data, mimetype: fileName.pathExtension)
                    (UIApplication.sharedApplication().delegate as! AppDelegate).fileName = nil
                    (UIApplication.sharedApplication().delegate as! AppDelegate).fileData = nil
                }
            }
        }
        self.attachmentsTableView.reloadData()
    }
    
    // MARK: - UITableViewDelegate
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return keys.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("AttachmentCell", forIndexPath: indexPath) as! AttachmentCell
        cell.imageViewPreview.image = self.images[indexPath.row]
        cell.labelFilename.text = self.keys[indexPath.row]
        var fileSize = Double((self.attachments.valueForKey(self.keys[indexPath.row]) as! NSData).length)
        if (fileSize / 1024) > 1 {
            var size = fileSize / 1024
            if (size / 1024) > 1 {
                cell.labelFileSize.text = "\(Int(size / 1024)) MB"
            } else {
                cell.labelFileSize.text = "\(Int(size)) KB"
            }
        } else {
            cell.labelFileSize.text = "\(Int(fileSize)) B"
        }
        if self.isSendAttachment {
            cell.selectionStyle = UITableViewCellSelectionStyle.None
        }
        if self.isViewAttachment {
            cell.selectionStyle = UITableViewCellSelectionStyle.Default
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.isViewAttachment {
            var manager = NSFileManager()
            var documentDirectory = ""
            let nsDocumentDirectory = NSSearchPathDirectory.DocumentDirectory
            let nsUserDomainMask = NSSearchPathDomainMask.UserDomainMask
            if let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true) {
                if paths.count > 0 {
                    if let dirPath = paths[0] as? String {
                        documentDirectory = dirPath
                    }
                }
            }
            var url = NSURL(fileURLWithPath: documentDirectory.stringByAppendingPathComponent(self.keys[indexPath.row]))
            manager.createFileAtPath(url!.path!, contents: self.attachments.valueForKey(self.keys[indexPath.row]) as? NSData, attributes: nil)
            self.createdFiles.append(url!)
            var docController = UIDocumentInteractionController(URL: url!)
            docController.presentOpenInMenuFromRect(CGRectZero, inView: self.view, animated: true)
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if self.isSendAttachment {
            if editingStyle == .Delete {
                self.deleteAttachment(indexPath.row)
            }
        }
    }
    
    // MARK: - UIActionSheetDelegate
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        switch buttonIndex {
        case 1:
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
            imagePicker.cameraDevice = UIImagePickerControllerCameraDevice.Rear
            imagePicker.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
            self.presentViewController(imagePicker, animated: true, completion: nil)
        case 2:
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            self.presentViewController(imagePicker, animated: true, completion: nil)
        default:
            break
        }
    }
    
    // MARK: - UIImagePickerControllerdelegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        let dictionary = NSDictionary(dictionary: info)
        
        if picker.sourceType == UIImagePickerControllerSourceType.PhotoLibrary {
            let refURL: NSURL = dictionary.valueForKey(UIImagePickerControllerReferenceURL) as! NSURL
            
            let assetsLibrary: ALAssetsLibrary = ALAssetsLibrary()
            assetsLibrary.assetForURL(refURL, resultBlock: { (imageAsset) -> Void in
                let imageRep: ALAssetRepresentation = imageAsset.defaultRepresentation()
                var data = NSData()
                switch imageRep.filename().pathExtension {
                case "PNG", "png": data = UIImagePNGRepresentation(dictionary.objectForKey(UIImagePickerControllerOriginalImage) as! UIImage)
                case "JPG", "JPEG": data = UIImageJPEGRepresentation(dictionary.objectForKey(UIImagePickerControllerOriginalImage) as! UIImage, 0.9)
                default: break
                }
                self.attachFile(imageRep.filename(), data: data, mimetype: imageRep.filename().pathExtension)
                self.attachmentsTableView.reloadData()
                }) { (error) -> Void in
                    
            }
        } else {
            let data = UIImageJPEGRepresentation(dictionary.objectForKey(UIImagePickerControllerOriginalImage) as! UIImage, 0.9)
            self.attachFile("image.JPG", data: data, mimetype: "JPG")
            self.attachmentsTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    
    // MARK: - Supportive Methods
    func pushImagePickerViewWithSender(sender: AnyObject) {
        var attachmentActionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Take Photo or Video", "Choose existing")
        attachmentActionSheet.tag = 2
        attachmentActionSheet.showInView(self.view)
    }
    
    func backToRootView(sender: AnyObject) {
        var manager = NSFileManager()
        for url in self.createdFiles {
            manager.removeItemAtURL(url, error: nil)
        }
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func attachFile(filename: String, data: NSData, mimetype: String) {
        if let attachment: AnyObject = self.attachments.valueForKey(filename) {
            var alert = UIAlertView(title: "Error", message: "Attachment already is part of this E-mail", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
            return
        }
        self.attachments.setValue(data, forKey: filename)
        self.keys.append(filename)
        var image = UIImage()
        if mimetype == "png" || mimetype == "PNG" || mimetype == "JPG" || mimetype == "JPEG" {
            image = UIImage(data: data)!
        } else {
            image = UIImage(named: "attachedFile.png")!
        }
        image = UIImage(CGImage: image.CGImage, scale: 1, orientation: image.imageOrientation)!
        self.images.append(image)
    }
    
    func deleteAttachment(removeIndex: Int) {
        self.images.removeAtIndex(removeIndex)
        self.attachments.removeObjectForKey(self.keys.removeAtIndex(removeIndex))
        self.attachmentsTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    
}
