//
//  KeyChainListTableViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 16.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import CoreData

class KeyChainListTableViewController: UITableViewController {
	
	var delegate: ContentViewControllerProtocol?
	var navController: UINavigationController!
	var keyDetailView: KeyDetailViewController?
	var keyList = [Key]()
	var keysFromCoreData = [Key]()
	var managedObjectContext: NSManagedObjectContext?
	var myGrayColer = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
	let myOpacity: CGFloat = 0.1
	let myOpacityFULL: CGFloat = 1.0
	let monthsInYear: Int = 12
	let monthsForFullValidity: Int = 6
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//Load some KeyItems
		loadInitialData()
		
		
		tableView.registerNib(UINib(nibName: "KeyItemTableViewCell", bundle: nil),forCellReuseIdentifier:"ListPrototypCell")
		
		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false
		
		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		//self.navigationItem.rightBarButtonItem = self.editButtonItem()
		
		var menuItem: UIBarButtonItem = UIBarButtonItem(title: "   Menu", style: .Plain, target: self, action: "menuTapped:")
		self.navigationItem.title = "KeyChain"
		self.navigationItem.leftBarButtonItem = menuItem
		self.navigationItem.rightBarButtonItem = self.editButtonItem()
		
	}
	
	override func viewWillAppear(animated: Bool) {
		loadInitialData()
		self.tableView.reloadData()
		
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: - Table view data source
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		
		// Return the number of sections.
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete method implementation.
		// Return the number of rows in the section.
		return self.keyList.count
	}
	
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
		let cell = tableView.dequeueReusableCellWithIdentifier("ListPrototypCell", forIndexPath: indexPath) as! KeyItemTableViewCell
		
		// Configure the cell...
		
		var keyItem = self.keyList[indexPath.row]
		
		// Fill data to labels
		cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
		cell.LabelKeyOwner.text = keyItem.userIDprimary
		cell.LabelMailAddress.text = keyItem.emailAddressPrimary
		cell.LabelKeyID.text = keyItem.keyID
		cell.secKey.image = UIImage(named: "sec_label.png")
		cell.pubKey.image = UIImage(named: "pub_label.png")
		cell.smime.image = UIImage(named: "smime_label.png")
		cell.pgp.image = UIImage(named: "pgp_label.png")
		
		// Set the right lables for the key type
		switch keyItem.keyType {
		case "SMIME":
			cell.pgp.alpha = myOpacity
			cell.smime.alpha = myOpacityFULL
		case "PGP":
			cell.smime.alpha = myOpacity
			cell.pgp.alpha = myOpacityFULL
		default:
			cell.smime.alpha = myOpacity
			cell.pgp.alpha = myOpacity
		}
		
		if keyItem.isSecretKey && keyItem.isPublicKey {
			cell.pubKey.alpha = myOpacityFULL
			cell.secKey.alpha = myOpacityFULL
		} else {
			if keyItem.isSecretKey {
				cell.pubKey.alpha = myOpacity
				cell.secKey.alpha = myOpacityFULL
			}
			
			if keyItem.isPublicKey {
				cell.secKey.alpha = myOpacity
				cell.pubKey.alpha = myOpacityFULL
			}
		}
		
		
		
		
		// Set the valid thru bar
		let currentDate = NSDate()
		if keyItem.validThru.year() >= currentDate.year() {
			if (keyItem.validThru.month() + (keyItem.validThru.year() - currentDate.year()) * monthsInYear) >= (currentDate.month() + monthsForFullValidity) {
				cell.validIndicator1.image = UIImage(named: "green_indicator.png")
				cell.validIndicator2.image = UIImage(named: "green_indicator.png")
				cell.validIndicator3.image = UIImage(named: "green_indicator.png")
				cell.validIndicator4.image = UIImage(named: "green_indicator.png")
				cell.validIndicator5.image = UIImage(named: "green_indicator.png")
				
			} else {
				cell.validIndicator1.image = UIImage(named: "yellow_indicator.png")
				cell.validIndicator2.image = UIImage(named: "yellow_indicator.png")
				cell.validIndicator3.image = UIImage(named: "yellow_indicator.png")
				cell.validIndicator4.image = UIImage(named: "gray_indicator.png")
				cell.validIndicator5.image = UIImage(named: "gray_indicator.png")
			}
			
		} else {
			cell.validIndicator1.image = UIImage(named: "red_indicator.png")
			cell.validIndicator2.image = UIImage(named: "gray_indicator.png")
			cell.validIndicator3.image = UIImage(named: "gray_indicator.png")
			cell.validIndicator4.image = UIImage(named: "gray_indicator.png")
			cell.validIndicator5.image = UIImage(named: "gray_indicator.png")
		}
		
		
		return cell
	}
	
	
	
	
	/*
	// Override to support conditional editing of the table view.
	override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
	// Return NO if you do not want the specified item to be editable.
	return true
	}
	*/
	
	/*
	// Override to support editing the table view.
	override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
	if editingStyle == .Delete {
	// Delete the row from the data source
	tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
	} else if editingStyle == .Insert {
	// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
	}
	}
	*/
	
	/*
	// Override to support rearranging the table view.
	override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
	
	}
	*/
	
	/*
	// Override to support conditional rearranging of the table view.
	override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
	// Return NO if you do not want the item to be re-orderable.
	return true
	}
	*/
	
	/*
	// MARK: - Navigation
	
	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
	// Get the new view controller using [segue destinationViewController].
	// Pass the selected object to the new view controller.
	}
	*/
	/*
	override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
	var detailview: KeyDetailViewController = KeyDetailViewController()
	self.presentViewController(detailview, animated: true) { () -> Void in
	
	}
	
	
	}
	*/
	
	func loadInitialData() {
		
		let appDel: AppDelegate? = UIApplication.sharedApplication().delegate as? AppDelegate
		if let appDelegate = appDel {
			self.managedObjectContext = appDelegate.managedObjectContext!
			var keyFetchRequest = NSFetchRequest(entityName: "Key")
			var error: NSError?
			var fetchedKeysFromCoreData = managedObjectContext!.executeFetchRequest(keyFetchRequest, error: &error) as? [Key]
			if error != nil {
				NSLog("Key fetchRequest: \(error?.localizedDescription)")
			} else {
				self.keysFromCoreData = fetchedKeysFromCoreData!
				
			}
			
			// check if sec and pub key with same keyID
			var secKeys = [Key]()
			var pubKeys = [Key]()
			for key in self.keysFromCoreData {
				if key.isPublicKey {
					pubKeys.append(key)
				}
				if key.isSecretKey {
					secKeys.append(key)
				}
			}
			
			for seckey in secKeys {
				for var i = 0; i < pubKeys.count; i++ {
					let pubkey = pubKeys[i]
					if seckey.keyID == pubkey.keyID {
						seckey.isPublicKey = true
						pubKeys.removeAtIndex(i)
					}
				}
			}
			
			self.keyList = secKeys + pubKeys
			
			
		}
	}
	
	
	@IBAction func menuTapped(sender: AnyObject) {
		self.delegate?.toggleLeftPanel()
	}
}

