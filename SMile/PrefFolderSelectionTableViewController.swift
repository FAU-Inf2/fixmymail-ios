//
//  PrefFolderSelectionTableViewController.swift
//  SMile
//
//  Created by Sebastian Thürauf on 29.07.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit

class PrefFolderSelectionTableViewController: UITableViewController {
	
	var emailAcc: EmailAccount?
	var StringForFolderBehavior: String?
	var selectedFolderPath: String?
	var folderPaths = [String]()
	var lastTappedIndexPath: NSIndexPath?
	var isChecked: [Bool] = [Bool]()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		loadData()

		tableView.registerNib(UINib(nibName: "AuthConTableViewCell", bundle: nil),forCellReuseIdentifier:"AuthConTableViewCell")
		self.navigationItem.title = self.StringForFolderBehavior
		
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
        return self.folderPaths.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AuthConTableViewCell", forIndexPath: indexPath) as! AuthConTableViewCell

        // Configure the cell...
		cell.textfield.text = self.folderPaths[indexPath.row]
		cell.textfield.enabled = false
		
		// if checked
		if self.isChecked[indexPath.row] {
			cell.accessoryType = UITableViewCellAccessoryType.Checkmark
		} else {
			cell.accessoryType = UITableViewCellAccessoryType.None
		}

        return cell
    }
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		for var i = 0; i < self.isChecked.count; i++ {
			self.isChecked[i] = false
		}
		
		self.isChecked[indexPath.row] = true
		
		if self.folderPaths[indexPath.row] == "Use account standard folders" {
			self.selectedFolderPath = ""
		} else {
			self.selectedFolderPath = self.folderPaths[indexPath.row]
		}
		// uncheck previous
		if self.lastTappedIndexPath != nil {
			self.isChecked[self.lastTappedIndexPath!.row] = false
		}
		
		self.lastTappedIndexPath = indexPath
		self.tableView.reloadData()
	}
	
	func loadData() {
		if self.emailAcc != nil {
			for folderObject in self.emailAcc!.folders {
				if let folder = folderObject as? ImapFolder {
					self.folderPaths.append(folder.mcoimapfolder.path)
				}
			}
		}
		
		self.folderPaths.sort(){$0 < $1}
		self.folderPaths.insert("Use account standard folders", atIndex: 0)

		for item in self.folderPaths {
			if item == self.selectedFolderPath {
				self.isChecked.append(true)
			} else {
				self.isChecked.append(false)
			}
		}
		if self.selectedFolderPath == "" {
			self.isChecked[0] = true
		}
	}
}
