//
//  PrefDownloadMailDurationTableViewController.swift
//  SMile
//
//  Created by Sebastian Thürauf on 03.09.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit

class PrefDownloadMailDurationTableViewController: UITableViewController {
        
	var selectedString: String = ""
	var options: [String] = [String]()
	var isChecked: [Bool] = [Bool]()
	var accounts: [EmailAccount] = [EmailAccount]();
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.registerNib(UINib(nibName: "AuthConTableViewCell", bundle: nil),forCellReuseIdentifier:"AuthConTableViewCell")
		self.navigationItem.title = "Download mails for"
		
		
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
		// Return the number of sections.
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// Return the number of rows in the section.
		return self.options.count
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		// uncheck previous
		for var i = 0; i < self.isChecked.count; i++ {
			self.isChecked[i] = false
		}
		
		self.isChecked[indexPath.row] = true
		self.selectedString = self.options[indexPath.row]
		
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
	
	
	func loadCellData() {
		
		self.options.append("One week")
		self.options.append("One month")
		self.options.append("Six months")
		self.options.append("One year")
		self.options.append("Ever")
		
		
		for entry in self.options {
			if self.selectedString == entry {
				self.isChecked.append(true)
			} else {
				self.isChecked.append(false)
			}
		}
	}
	
}
