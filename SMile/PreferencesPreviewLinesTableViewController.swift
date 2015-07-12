//
//  PreferencesPreviewLinesTableViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 27.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class PreferencesPreviewLinesTableViewController: UITableViewController {
        
	var selectedString: String = ""
	var options: [String] = [String]()
	var lastTappedIndexPath: NSIndexPath?
	var isChecked: [Bool] = [Bool]()
	var accounts: [EmailAccount] = [EmailAccount]();
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.registerNib(UINib(nibName: "AuthConTableViewCell", bundle: nil),forCellReuseIdentifier:"AuthConTableViewCell")
		self.navigationItem.title = "Number of Preview lines"
		
		
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
		for var i = 0; i < self.isChecked.count; i++ {
			self.isChecked[i] = false
		}
		
		self.isChecked[indexPath.row] = true
		self.selectedString = self.options[indexPath.row]
		
		// uncheck previous
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
	
	
	func loadCellData() {
		//load numbers
		for i in 0...5 {
			var entry: String = String(i)
			self.options.append(entry)
			if self.selectedString == entry {
				self.isChecked.append(true)
			} else {
				self.isChecked.append(false)
			}
		}
	}
    
}
