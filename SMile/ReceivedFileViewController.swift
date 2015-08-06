//
//  ReceivedFileViewController.swift
//  SMile
//
//  Created by Sebastian Thürauf on 04.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit

class ReceivedFileViewController: UIViewController {
	@IBOutlet weak var image: UIImageView!
	@IBOutlet weak var label: UILabel!
	@IBOutlet weak var navigationBar: UINavigationBar!
	@IBOutlet weak var toolbar: UIToolbar!
	var url: NSURL?
	var file: NSData?
	var fileManager: NSFileManager?
	

    override func viewDidLoad() {
        super.viewDidLoad()
		
		// load file
		self.fileManager = NSFileManager.defaultManager()
		self.file = self.fileManager!.contentsAtPath(self.url!.path!)
		
        // Do any additional setup after loading the view.
		// set navigationbar
		let navItem: UINavigationItem = UINavigationItem(title: "Received File")
		var flexSpaceItem: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
		var cancelItem: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancelTapped:")
		var importButton: UIBarButtonItem = UIBarButtonItem(title: "Import key", style: .Plain, target: self, action: "importTapped:")
		var decryptButton: UIBarButtonItem = UIBarButtonItem(title: "Decrypt file", style: .Plain, target: self, action: "decryptTapped:")
		// file is a .asc or .gpg file
		if self.fileIsKeyfile(self.fileManager!.displayNameAtPath(self.url!.path!)) == true {
			if self.isPGPKey(self.url!) == true {
				navItem.rightBarButtonItems = [importButton]
			} else {
				navItem.rightBarButtonItems = [decryptButton]
			}
			
		}
		navItem.leftBarButtonItems = [cancelItem]
		navigationBar.items = [navItem]
		
		// set toolbar
		var composeButton: UIBarButtonItem = UIBarButtonItem(title: "Attach to Email", style: .Plain,  target: self, action: "showEmptyMailSendView:")
		var actionButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "actionTapped:")
		var items = [actionButton, UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil), composeButton]
		self.toolbar.setItems(items, animated: false)
		
		// set view content
		self.label.text = self.fileManager!.displayNameAtPath(self.url!.path!)
		self.image.image = self.getUImageFromFilename(self.fileManager!.displayNameAtPath(self.url!.path!))
		
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

	
	// MARK: - Navigation
	
	@IBAction func showEmptyMailSendView(sender: AnyObject) -> Void {
		// use file for email attachment
		//self.showMailSendView(nil, ccRecipients: nil, bccRecipients: nil, subject: nil, textBody: nil)
	}
	
	@IBAction func cancelTapped(sender: AnyObject) -> Void {
		if self.fileManager!.removeItemAtURL(self.url!, error: nil) {
			NSLog("File : " + self.fileManager!.displayNameAtPath(self.url!.path!) + " deleted")
		}
		self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
	}
	
	@IBAction func importTapped(sender: AnyObject) -> Void {
		// import key
		var crypto: SMileCrypto = SMileCrypto()
		var success = crypto.importKey(self.url!)
		if success {
			self.label.text = "Import Successful"
			self.image.image = UIImage(named: "Checkmark-icon.png")
			self.delay(1.0) {
				if self.fileManager!.removeItemAtURL(self.url!, error: nil) {
					NSLog("File : " + self.fileManager!.displayNameAtPath(self.url!.path!) + " deleted")
				}
				self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
			}
		} else {
			self.label.text = "Sorry, something went wrong!"
			self.image.image = UIImage(named: "x_icon.png")
		}
		
	}
	
	@IBAction func decryptTapped(sender: AnyObject) -> Void {
		var crypto: SMileCrypto = SMileCrypto()
		crypto.printAllPublicKeys()
		crypto.printAllSecretKeys()
		
		var decryptedFile = crypto.decryptFile(self.url!, passphrase: "GoMADyoumust1!", encryptionType: "PGP")
		if decryptedFile != nil {
			self.fileManager!.removeItemAtURL(self.url!, error: nil)
			self.url = decryptedFile!
			self.label.text = self.fileManager!.displayNameAtPath(self.url!.path!)
			self.image.image = self.getUImageFromFilename(self.fileManager!.displayNameAtPath(self.url!.path!))
			self.file = self.fileManager!.contentsAtPath(self.url!.path!)
		}
	}
	
	
	@IBAction func actionTapped(sender: AnyObject) -> Void {
		
	}
	
	func getUImageFromFilename(filename: String) -> UIImage? {
		var fileimage: UIImage?
		switch filename {
		case let s where s.rangeOfString(".asc") != nil:
			fileimage = UIImage(named: "keyicon.png")
		// add more cases for different document types
		case let s where s.rangeOfString(".gpg") != nil:
			fileimage = UIImage(named: "fileicon_lock.png")
		default:
			fileimage = UIImage(named: "fileicon_standard.png")
		}
		return fileimage
			
	}
	
	func fileIsKeyfile(filename: String) -> Bool {
		if filename.rangeOfString(".asc") != nil || filename.rangeOfString(".gpg") != nil {
			return true
		} else {
			return false
		}
	}
	
	func isPGPKey(fileUrl: NSURL) -> Bool {
		if let fileContent = String(contentsOfFile: fileUrl.path!, encoding: NSUTF8StringEncoding, error: nil) {
			if fileContent.rangeOfString("-----BEGIN PGP PUBLIC KEY BLOCK-----") != nil
				|| fileContent.rangeOfString("-----BEGIN PGP PRIVATE KEY BLOCK-----") != nil {
				return true
			}
		}
		
		return false
	}
	
	// delay block for seconds
	func delay(delay:Double, closure:()->()) {
		dispatch_after(
			dispatch_time(
				DISPATCH_TIME_NOW,
				Int64(delay * Double(NSEC_PER_SEC))
			),
			dispatch_get_main_queue(), closure)
	}
	
}
