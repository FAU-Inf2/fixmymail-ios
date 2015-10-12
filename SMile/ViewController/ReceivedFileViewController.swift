//
//  ReceivedFileViewController.swift
//  SMile
//
//  Created by Sebastian Thürauf on 04.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import Locksmith

@objc
protocol ReceivedFileViewControllerProtocol {
	func didFinishWithKeySelection(selectedKey: Key) -> Void
}

class ReceivedFileViewController: UIViewController {
	@IBOutlet weak var image: UIImageView!
	@IBOutlet weak var label: UILabel!
	
	weak var delegate: ReceivedFileViewControllerProtocol?
//	@IBOutlet weak var navigationBar: UINavigationBar!
//	@IBOutlet weak var toolbar: UIToolbar!
	var url: NSURL?
	var file: NSData?
	var fileManager: NSFileManager?
	var docController: UIDocumentInteractionController?
	var crypto: SMileCrypto = SMileCrypto()
	

    override func viewDidLoad() {
        super.viewDidLoad()
		
		// load file
		self.fileManager = NSFileManager.defaultManager()
		self.file = self.fileManager!.contentsAtPath(self.url!.path!)
		
		
        // Do any additional setup after loading the view.
		// set navigationbar
		let cancelItem: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancelTapped:")
		let importButton: UIBarButtonItem = UIBarButtonItem(title: "Import key", style: .Plain, target: self, action: "importTapped:")
		let decryptButton: UIBarButtonItem = UIBarButtonItem(title: "Decrypt file", style: .Plain, target: self, action: "decryptTapped:")
		let encryptButton: UIBarButtonItem = UIBarButtonItem(title: "Encrypt file", style: .Plain, target: self, action: "encryptTapped:")
		// file is a .asc or .gpg file
		if self.fileIsPGPfile(self.fileManager!.displayNameAtPath(self.url!.path!)) == true {
			if self.isPGPKey(self.url!) == true {
				self.navigationItem.rightBarButtonItems = [importButton]
			} else if self.isPGPArmoredMessage(self.url!) == true {
				self.navigationItem.rightBarButtonItems = [decryptButton]
			}
			
		} else {
			// other files
			self.navigationItem.rightBarButtonItems = [encryptButton]
		}
		self.navigationItem.leftBarButtonItems = [cancelItem]
		
		// set toolbar
		let composeButton: UIBarButtonItem = UIBarButtonItem(title: "Attach to Email", style: .Plain,  target: self, action: "showEmptyMailSendView:")
		let actionButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "actionTapped:")
		let items = [actionButton, UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil), composeButton]
		self.navigationController?.visibleViewController!.setToolbarItems(items, animated: true)
		self.navigationController?.setToolbarHidden(false, animated: true)
		
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
        (UIApplication.sharedApplication().delegate as! AppDelegate).fileName = self.fileManager!.displayNameAtPath(self.url!.path!)
        (UIApplication.sharedApplication().delegate as! AppDelegate).fileData = file
	(UIApplication.sharedApplication().delegate as! AppDelegate).fileExtension = self.fileManager!.displayNameAtPath(self.url!.pathExtension!)
        self.cancelTapped(self)
	}
	
	@IBAction func cancelTapped(sender: AnyObject) -> Void {
		do {
			try self.fileManager!.removeItemAtURL(self.url!)
			NSLog("File : " + self.fileManager!.displayNameAtPath(self.url!.path!) + " deleted")
		} catch _ {
		}
		self.navigationController?.popViewControllerAnimated(true)
	}
	
	@IBAction func importTapped(sender: AnyObject) -> Void {
		// import key
		let success = crypto.importKey(self.url!)
		if success {
			let button = sender as! UIBarButtonItem
			button.enabled = false
			self.label.text = "Import Successful"
			self.image.image = UIImage(named: "Checkmark-icon.png")
			self.delay(1.0) {
				do {
					try self.fileManager!.removeItemAtURL(self.url!)
					NSLog("File : " + self.fileManager!.displayNameAtPath(self.url!.path!) + " deleted")
				} catch _ {
				}
				self.cancelTapped(self)
			}
		} else {
			self.label.text = "Sorry, something went wrong!"
			self.image.image = UIImage(named: "x_icon.png")
		}
		
	}
	
	@IBAction func decryptTapped(sender: AnyObject) -> Void {
		var passphrase: String?
		if let encryptedData = NSData(contentsOfURL: self.url!) {
			if let key = crypto.getKeyforEncryptedMessage(encryptedData) {
				if let dictionary = Locksmith.loadDataForUserAccount(key.keyID) {
					passphrase = dictionary["PassPhrase"] as? String
				}
					// ask the user for passphrase
					var inputTextField: UITextField?
					let passphrasePrompt = UIAlertController(title: "Enter Passphrase", message: "Please enter the passphrase for key: \(key.keyID)", preferredStyle: .Alert)
					passphrasePrompt.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
					passphrasePrompt.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
						passphrase = inputTextField!.text
						if passphrase != nil {
							let (error, decryptedFile) = self.crypto.decryptFile(self.url!, passphrase: passphrase!, encryptionType: "PGP")
							if decryptedFile != nil && error == nil {
								let button = sender as! UIBarButtonItem
								button.enabled = false
								do {
									try self.fileManager!.removeItemAtURL(self.url!)
								} catch _ {
								}
								self.url = decryptedFile!
								self.label.text = self.fileManager!.displayNameAtPath(self.url!.path!)
								self.image.image = self.getUImageFromFilename(self.fileManager!.displayNameAtPath(self.url!.path!))
								self.file = self.fileManager!.contentsAtPath(self.url!.path!)
								
							} else {
								if error != nil {
									NSLog("Decrytpion Error: \(error?.localizedDescription)")
									self.decryptTapped(sender)
								}
							}
						}
					}))
					passphrasePrompt.addAction(UIAlertAction(title: "OK and Save Passphrase", style: .Default, handler: {(action) -> Void in
						passphrase = inputTextField!.text
						if passphrase != nil {
							
							do {
								try Locksmith.deleteDataForUserAccount(key.keyID)
							} catch _ {}
							do {
								try Locksmith.saveData(["PassPhrase": passphrase!], forUserAccount: key.keyID)
							} catch let error as NSError {
								NSLog("Locksmith: \(error.localizedDescription)")
							}
							
							
							let (error, decryptedFile) = self.crypto.decryptFile(self.url!, passphrase: passphrase!, encryptionType: "PGP")
							if decryptedFile != nil && error == nil {
								let button = sender as! UIBarButtonItem
								button.enabled = false
								do {
									try self.fileManager!.removeItemAtURL(self.url!)
								} catch _ {
								}
								self.url = decryptedFile!
								self.label.text = self.fileManager!.displayNameAtPath(self.url!.path!)
								self.image.image = self.getUImageFromFilename(self.fileManager!.displayNameAtPath(self.url!.path!))
								self.file = self.fileManager!.contentsAtPath(self.url!.path!)
								
							} else {
								if error != nil {
									NSLog("Decrytpion Error: \(error?.localizedDescription)")
									self.decryptTapped(sender)
								}
							}
						}
					}))
					passphrasePrompt.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
						textField.placeholder = "Passphrase"
						textField.secureTextEntry = true
						if passphrase != nil {
							textField.text = passphrase
						}
						inputTextField = textField
						
					})
					presentViewController(passphrasePrompt, animated: true, completion: nil)
				
			}
			
		}
	}
	
	@IBAction func encryptTapped(sender: AnyObject) -> Void {
		let keyChainVC = KeyChainListTableViewController(nibName: "KeyChainListTableViewController", bundle: nil)
		keyChainVC.isInKeySelectionMode = true
		keyChainVC.receivedFileDelegate = self
		let navbar = UINavigationController.init(rootViewController: keyChainVC)
		self.navigationController?.presentViewController(navbar, animated: true, completion: nil)
		
	}
	// called after a key was selected in KeyChainListTableViewController
	func encrypt(keyForEncrypt: Key) {
		let (error, encryptedFile) = crypto.encryptFile(self.url!, keyIdentifier: keyForEncrypt.keyID, encryptionType: "PGP")
		if encryptedFile != nil && error == nil {
			self.navigationItem.rightBarButtonItem?.enabled = false
			do {
				try self.fileManager!.removeItemAtURL(self.url!)
			} catch _ {
			}
			self.url = encryptedFile!
			self.file = self.fileManager!.contentsAtPath(self.url!.path!)
			self.label.text = self.fileManager!.displayNameAtPath(self.url!.path!)
			self.image.image = self.getUImageFromFilename(self.fileManager!.displayNameAtPath(self.url!.path!))
			
		} else {
			if error != nil {
				NSLog("Encryption Error: \(error?.localizedDescription)")
			}
		}
	}
	
	
	@IBAction func actionTapped(sender: AnyObject) -> Void {
		self.docController = UIDocumentInteractionController(URL: self.url!)
		self.docController!.presentOpenInMenuFromRect(CGRectZero, inView: self.view, animated: true)
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
	
	func fileIsPGPfile(filename: String) -> Bool {
		if filename.rangeOfString(".asc") != nil || filename.rangeOfString(".gpg") != nil {
			return true
		} else {
			return false
		}
	}
	
	func isPGPKey(fileUrl: NSURL) -> Bool {
		if let fileContent = try? String(contentsOfFile: fileUrl.path!, encoding: NSUTF8StringEncoding) {
			if fileContent.rangeOfString("-----BEGIN PGP PUBLIC KEY BLOCK-----") != nil
				|| fileContent.rangeOfString("-----BEGIN PGP PRIVATE KEY BLOCK-----") != nil {
				return true
			}
		}
		
		return false
	}
	
	func isPGPArmoredMessage(fileUrl: NSURL) -> Bool {
		if let fileContent = try? String(contentsOfFile: fileUrl.path!, encoding: NSUTF8StringEncoding) {
			if fileContent.rangeOfString("-----BEGIN PGP MESSAGE-----") != nil {
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

extension ReceivedFileViewController: ReceivedFileViewControllerProtocol {
	
	func didFinishWithKeySelection(selectedKey: Key) -> Void {
		print("Got the key: \(selectedKey.keyID)")
		self.encrypt(selectedKey)
	
	}

}
