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
		
		loadData()

        // Do any additional setup after loading the view.
		// set navigationbar
		let navItem: UINavigationItem = UINavigationItem(title: "Received File")
		var flexSpaceItem: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
		var cancelItem: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancelTapped:")
		var importButton: UIBarButtonItem = UIBarButtonItem(title: "Import Key", style: .Plain, target: self, action: "importTapped:")
		if self.fileIsKeyfile(self.fileManager!.displayNameAtPath(self.url!.path!)) == false {
			importButton.enabled = false
		}
		navItem.leftBarButtonItems = [cancelItem]
		navItem.rightBarButtonItems = [importButton]
		navigationBar.items = [navItem]
		
		// set toolbar
		var composeButton: UIBarButtonItem = UIBarButtonItem(title: "Attach to Email", style: .Plain,  target: self, action: "showEmptyMailSendView:")
		var items = [UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil), composeButton]
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
		if self.fileManager!.removeItemAtURL(url!, error: nil) {
			NSLog("File : " + self.fileManager!.displayNameAtPath(self.url!.path!) + " deleted")
		}
		self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
	}
	
	@IBAction func importTapped(sender: AnyObject) -> Void {
		// import key
	}
	
	// MARK: - Load Data
	func loadData() {
		self.fileManager = NSFileManager.defaultManager()
		self.file = self.fileManager!.contentsAtPath(self.url!.path!)
	}
	
	func getUImageFromFilename(filename: String) -> UIImage? {
		var fileimage: UIImage?
		switch filename {
		case let s where s.rangeOfString(".asc") != nil:
			fileimage = UIImage(named: "keyicon.png")
		// add more cases for different document types
		// case let s where s.rangeOfString(".) != nil:
		default:
			fileimage = UIImage(named: "fileicon_standard.png")
		}
		return fileimage
			
	}
	
	func fileIsKeyfile(filename: String) -> Bool {
		if filename.rangeOfString(".asc") != nil {
			return true
		} else {
			return false
		}
	}
	
}
