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
//import Photos

class AttachmentsViewController : UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate {
    
    // MARK: - Initialisation
    @IBOutlet var attachmentsTableView: UITableView!
    
    var attachments: NSMutableDictionary = NSMutableDictionary()
    var keys: [String] = [String]()
    var images: [UIImage] = [UIImage]()
    
    var createdFiles: [NSURL] = [NSURL]()
    
    var isSendAttachment = false
    var isViewAttachment = false
    
    var currentShareURL: NSURL?
    var documentInteractionController: UIDocumentInteractionController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Attachments"
        
        self.attachmentsTableView.registerNib(UINib(nibName: "AttachmentCell", bundle: nil), forCellReuseIdentifier: "AttachmentCell")
        
        if self.isSendAttachment {
            let buttonImagePicker: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "pushImagePickerViewWithSender:")
            self.navigationItem.rightBarButtonItem = buttonImagePicker
        }
        if self.isViewAttachment {
            let buttonBack: UIBarButtonItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Plain, target: self, action: "backToRootView:")
            self.navigationItem.leftBarButtonItem = buttonBack
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        if let fileName = (UIApplication.sharedApplication().delegate as! AppDelegate).fileName {
            if let data = (UIApplication.sharedApplication().delegate as! AppDelegate).fileData {
                if self.isSendAttachment {
                    self.attachFile(fileName, data: data, mimetype: getPathExtensionFromString(fileName)!)
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
        let cell = tableView.dequeueReusableCellWithIdentifier("AttachmentCell", forIndexPath: indexPath) as! AttachmentCell
        cell.imageViewPreview.image = self.images[indexPath.row]
        cell.labelFilename.text = self.keys[indexPath.row]
        let fileSize = Double((self.attachments.valueForKey(self.keys[indexPath.row]) as! NSData).length)
        if (fileSize / 1024) > 1 {
            let size = fileSize / 1024
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
            let manager = NSFileManager.defaultManager()
            var documentDirectory = ""
            let nsDocumentDirectory = NSSearchPathDirectory.DocumentDirectory
            let nsUserDomainMask = NSSearchPathDomainMask.UserDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if paths.count > 0 {
                if paths.count > 0 {
                    let dirPath = paths[0]
                    documentDirectory = dirPath
                }
            }
            self.currentShareURL = NSURL(fileURLWithPath: appendPathExtensionToString(documentDirectory, andPathExtension: self.keys[indexPath.row])!)
            if manager.createFileAtPath(self.currentShareURL!.path!, contents: self.attachments.valueForKey(self.keys[indexPath.row]) as? NSData, attributes: nil) {
                self.createdFiles.append(self.currentShareURL!)
                self.documentInteractionController = UIDocumentInteractionController(URL: self.currentShareURL!)
                self.documentInteractionController.presentOpenInMenuFromRect(CGRectZero, inView: self.view, animated: true)
            } else {
                print("Could not write file!")
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if self.isSendAttachment {
            if editingStyle == .Delete {
                self.deleteAttachment(indexPath.row)
            }
        }
    }
    
    // MARK: - UIImagePickerControllerdelegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        let dictionary = NSDictionary(dictionary: info)
        
        if picker.sourceType == UIImagePickerControllerSourceType.PhotoLibrary {
            let refURL: NSURL = dictionary.valueForKey(UIImagePickerControllerReferenceURL) as! NSURL
            
            let assetsLibrary: ALAssetsLibrary = ALAssetsLibrary()
            assetsLibrary.assetForURL(refURL, resultBlock: { (imageAsset) -> Void in
                let imageRep: ALAssetRepresentation = imageAsset.defaultRepresentation()
                var data = NSData()
                switch getPathExtensionFromString(imageRep.filename())! {
                case "PNG", "png": data = UIImagePNGRepresentation(dictionary.objectForKey(UIImagePickerControllerOriginalImage) as! UIImage)!
                case "JPG", "JPEG": data = UIImageJPEGRepresentation(dictionary.objectForKey(UIImagePickerControllerOriginalImage) as! UIImage, 0.9)!
                default: break
                }
                self.attachFile(imageRep.filename(), data: data, mimetype: getPathExtensionFromString(imageRep.filename())!)
                self.attachmentsTableView.reloadData()
                }) { (error) -> Void in
                    
            }
        } else {
            let data = UIImageJPEGRepresentation(dictionary.objectForKey(UIImagePickerControllerOriginalImage) as! UIImage, 0.9)
            self.attachFile("image.JPG", data: data!, mimetype: "JPG")
            self.attachmentsTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    
    // MARK: - Supportive Methods
    func pushImagePickerViewWithSender(sender: AnyObject) {
        
        let attachmentActionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .Default) { (action) -> Void in
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
            imagePicker.cameraDevice = UIImagePickerControllerCameraDevice.Rear
            imagePicker.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        let choosePhotoAction = UIAlertAction(title: "Choose existing", style: .Default) { (action) -> Void in
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        attachmentActionSheet.addAction(cancelAction)
        attachmentActionSheet.addAction(takePhotoAction)
        attachmentActionSheet.addAction(choosePhotoAction)
        self.presentViewController(attachmentActionSheet, animated: true, completion: nil)
    }
    
    func backToRootView(sender: AnyObject) {
        let manager = NSFileManager()
        for url in self.createdFiles {
            do {
                try manager.removeItemAtURL(url)
            } catch _ {
            }
        }
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func attachFile(filename: String, data: NSData, mimetype: String) {
        if let _: AnyObject = self.attachments.valueForKey(filename) {
            
            let alert = UIAlertController(title: "Error", message: "Attachment already is part of this E-mail", preferredStyle: .Alert)
            let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
            alert.addAction(cancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
            
            return
        }
        self.attachments.setValue(data, forKey: filename)
        self.keys.append(filename)
        var image = UIImage()
        if mimetype.lowercaseString.rangeOfString("png") != nil || mimetype.lowercaseString.rangeOfString("jpg") != nil || mimetype.lowercaseString.rangeOfString("jpeg") != nil {
            print(NSString(data: data, encoding: NSUTF8StringEncoding))
            image = UIImage(data: data)!
        } else {
            image = UIImage(named: "attachedFile.png")!
        }
        image = UIImage(CGImage: image.CGImage!, scale: 1, orientation: image.imageOrientation)
        self.images.append(image)
    }
    
    func deleteAttachment(removeIndex: Int) {
        self.images.removeAtIndex(removeIndex)
        self.attachments.removeObjectForKey(self.keys.removeAtIndex(removeIndex))
        self.attachmentsTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    
}
