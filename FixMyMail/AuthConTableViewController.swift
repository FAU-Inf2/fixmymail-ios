//
//  AuthConTableViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 06.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class AuthConTableViewController: UITableViewController {
	
	var selectedString: String = ""
	var labelPreviousVC: String = ""
	var options: [String] = [String]()
	var lastTappedIndexPath: NSIndexPath?
	var isChecked: [Bool] = [Bool]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.registerNib(UINib(nibName: "AuthConTableViewCell", bundle: nil),forCellReuseIdentifier:"AuthConTableViewCell")
		
		if self.labelPreviousVC == "IMAP Auth:" || self.labelPreviousVC == "SMTP Auth:" {
			self.navigationItem.title = "Authentication Type"
		}
		if self.labelPreviousVC == "IMAP ConType:" ||  self.labelPreviousVC == "SMTP ConType:" {
			self.navigationItem.title = "Connection Type"
		}
		
		loadCellData()
		
		
		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false
		
		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: - Table view data source
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		// #warning Potentially incomplete method implementation.
		// Return the number of sections.
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete method implementation.
		// Return the number of rows in the section.
		return self.options.count
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		for var i = 0; i < self.isChecked.count; i++ {
			self.isChecked[i] = false
		}
		
		self.isChecked[indexPath.row] = true
		
		self.selectedString = self.options[indexPath.row]
		
		// unceck previous
		if self.lastTappedIndexPath != nil {
			self.isChecked[self.lastTappedIndexPath!.row] = false
		}
		
		self.lastTappedIndexPath = indexPath
		self.tableView.reloadData()
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("AuthConTableViewCell", forIndexPath: indexPath) as! AuthConTableViewCell
		
		// Configure the cell...
		
		cell.textfield.text = self.options[indexPath.row]
		cell.textfield.enabled = false
		
		// if checked
		if self.isChecked[indexPath.row] {
			cell.accessoryType = UITableViewCellAccessoryType.Checkmark
		} else {
			cell.accessoryType = UITableViewCellAccessoryType.None
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
	
	func loadCellData() {
		
		if self.labelPreviousVC == "IMAP Auth:" || self.labelPreviousVC == "SMTP Auth:" {
			// Authentication Type
			self.options.append("None")
			self.options.append("CRAM-MD5")
			self.options.append("Plain")
			self.options.append("GSSAPI")
			self.options.append("DIGEST-MD5")
			self.options.append("Login")
			self.options.append("Secure Remote Password")
			self.options.append("NTLM Authentication")
			self.options.append("Kerberos 4")
			self.options.append("OAuth2")
			self.options.append("OAuth2 on Outlook.com")
		}
		if self.labelPreviousVC == "IMAP ConType:" ||  self.labelPreviousVC == "SMTP ConType:" {
			// Connection Type
			self.options.append("Clear-Text")
			self.options.append("TLS")
			self.options.append("STARTTLS")		}
		
		
		for item in self.options {
			if item == self.selectedString {
				self.isChecked.append(true)
			} else {
				self.isChecked.append(false)
			}
		}
	}
	
}
