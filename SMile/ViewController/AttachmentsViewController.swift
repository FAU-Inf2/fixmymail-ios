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

class AttachmentsViewController : UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate/*, AttachmentCellDelegate*/ {
    
    @IBOutlet var attachmentsTableView: UITableView!
    
    var attachments: NSMutableDictionary = NSMutableDictionary()
    var keys: [String] = [String]()
    var images: [UIImage] = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Attachments"
        
        self.attachmentsTableView.registerNib(UINib(nibName: "AttachmentCell", bundle: nil), forCellReuseIdentifier: "AttachmentCell")
        
        var buttonImagePicker: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "pushImagePickerViewWithSender:")
        self.navigationItem.rightBarButtonItem = buttonImagePicker
    }
    
    override func viewDidAppear(animated: Bool) {
        if let fileName = (UIApplication.sharedApplication().delegate as! AppDelegate).fileName {
            if let data = (UIApplication.sharedApplication().delegate as! AppDelegate).fileData {
                self.attachFile(fileName, data: data, mimetype: fileName.pathExtension)
                (UIApplication.sharedApplication().delegate as! AppDelegate).fileName = nil
                (UIApplication.sharedApplication().delegate as! AppDelegate).fileData = nil
            }
        }
        self.attachmentsTableView.reloadData()
    }
    
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
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            self.deleteAttachment(indexPath.row)
        }
    }
    
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
    
    func pushImagePickerViewWithSender(sender: AnyObject) {
        var attachmentActionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Take Photo or Video", "Choose existing")
        attachmentActionSheet.tag = 2
        attachmentActionSheet.showInView(self.view)
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
        image = UIImage(CGImage: image.CGImage, scale: 1, orientation: UIImageOrientation.Up)!
        self.images.append(image)
    }
    
    func deleteAttachment(removeIndex: Int) {
        self.images.removeAtIndex(removeIndex)
        self.attachments.removeObjectForKey(self.keys.removeAtIndex(removeIndex))
        self.attachmentsTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    
}
