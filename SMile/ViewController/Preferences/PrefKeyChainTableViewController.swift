//
//  PrefKeyChainTableViewController.swift
//  SMile
//
//  Created by Sebastian Thürauf on 11.10.15.
//  Copyright © 2015 SMile. All rights reserved.
//

import UIKit
import CoreData
import Locksmith

class PrefKeyChainTableViewController: UITableViewController {
	
	var sections = [String]()
	var rows = [AnyObject]()
	let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
	var managedObjectContext: NSManagedObjectContext?
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.registerNib(UINib(nibName: "SwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "SwitchTableViewCell")
		tableView.registerNib(UINib(nibName: "AuthConTableViewCell", bundle: nil),forCellReuseIdentifier:"AuthConTableViewCell")
		self.navigationItem.title = "KeyChain Preferences"
		self.sections = ["", "", ""]
		
		loadData()
		
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: - Table view data source
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		// Return the number of sections.
		return self.sections.count
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.rows[section].count
	}
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return self.sections[section]
	}
	
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cellString = self.rows[indexPath.section][indexPath.row] as! String
		if cellString == "Auto encrypt if possible" || cellString == "Auto encrypt self" {
			let cell = tableView.dequeueReusableCellWithIdentifier("SwitchTableViewCell", forIndexPath: indexPath) as! SwitchTableViewCell
			cell.label.text = cellString
			if cellString == "Auto encrypt if possible" {
				cell.activateSwitch.addTarget(self, action: Selector("stateChanged:"), forControlEvents: UIControlEvents.ValueChanged)
				cell.activateSwitch.on = defaults.boolForKey("autoEncrypt")
			}
			if cellString == "Auto encrypt self" {
				cell.activateSwitch.addTarget(self, action: Selector("stateChanged:"), forControlEvents: UIControlEvents.ValueChanged)
				cell.activateSwitch.on = defaults.boolForKey("autoEncryptSelf")
			}
			return cell
		} else {
			let cell = tableView.dequeueReusableCellWithIdentifier("AuthConTableViewCell", forIndexPath: indexPath) as! AuthConTableViewCell
			cell.textfield.text = cellString
			cell.textfield.textColor = UIColor.redColor()
			cell.textfield.userInteractionEnabled = false
			cell.textfield.enabled = false
			return cell
		}
		
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let cellString = self.rows[indexPath.section][indexPath.row] as! String
		if cellString == "Delete all saved passphrases" {
			var keysInCoreData = [Key]()
			
			// fetch keys from coreData
			let appDel: AppDelegate? = UIApplication.sharedApplication().delegate as? AppDelegate
			if let appDelegate = appDel {
				self.managedObjectContext = appDelegate.managedObjectContext!
				let keyFetchRequest = NSFetchRequest(entityName: "Key")
				do {
					keysInCoreData = try managedObjectContext!.executeFetchRequest(keyFetchRequest) as! [Key]
				} catch _ {
				}
			}
			if keysInCoreData.count > 0 {
				for key in keysInCoreData {
					do {
						try Locksmith.deleteDataForUserAccount(key.keyID)
					} catch _ {
					}
				}
			}
		}
		
		self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
	}
	
	func loadData() {
		self.rows.append(["Auto encrypt if possible", "Auto encrypt self"])
		self.rows.append([])
		self.rows.append(["Delete all saved passphrases"])
	}
	
	// set value if switchstate has changed
	func stateChanged(switchState: UISwitch) {
		let cell = switchState.superview?.superview as! SwitchTableViewCell
		if cell.label.text == "Auto encrypt if possible" {
			NSUserDefaults.standardUserDefaults().setBool(switchState.on, forKey: "autoEncrypt")
		}
		if cell.label.text == "Auto encrypt self" {
			NSUserDefaults.standardUserDefaults().setBool(switchState.on, forKey: "autoEncryptSelf")
		}
	}
}
