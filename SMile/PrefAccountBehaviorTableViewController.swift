//
//  PrefAccountBehaviorTableViewController.swift
//  SMile
//
//  Created by Sebastian Thürauf on 29.07.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit

class PrefAccountBehaviorTableViewController: UITableViewController {
	
	var emailAcc: EmailAccount?
	var entries = [String: String]()
	var labelStrings = [String]()
	var folderVCs:[PrefFolderSelectionTableViewController?] = [nil,nil,nil,nil]
        
    override func viewDidLoad() {
        super.viewDidLoad()
		
		loadData()

		tableView.registerNib(UINib(nibName: "PreferenceAccountTableViewCell", bundle: nil),forCellReuseIdentifier:"PreferenceAccountCell")
		self.navigationItem.title = "Account behavior"
		
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
	
	override func viewWillAppear(animated: Bool) {
		for var i = 0; i < self.folderVCs.count; i++ {
			if self.folderVCs[i] != nil {
				self.entries[self.labelStrings[i]] = self.folderVCs[i]!.selectedFolderPath!
			}
		}
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
        // Return the number of rows in the section.
        return self.entries.count
    }

	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PreferenceAccountCell", forIndexPath: indexPath) as! PreferenceAccountTableViewCell
		// Configure the cell...
		cell.labelCellContent.text = self.labelStrings[indexPath.row]
		cell.textfield.text = self.entries[self.labelStrings[indexPath.row]]
		cell.textfield.textAlignment = NSTextAlignment.Right
		cell.textfield.enabled = false
		cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator

        return cell
    }
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if self.folderVCs[indexPath.row] == nil {
			self.folderVCs[indexPath.row] = PrefFolderSelectionTableViewController(nibName: "PrefFolderSelectionTableViewController", bundle: nil)
			self.folderVCs[indexPath.row]!.emailAcc = self.emailAcc!
			self.folderVCs[indexPath.row]!.StringForFolderBehavior = self.labelStrings[indexPath.row]
			self.folderVCs[indexPath.row]!.selectedFolderPath = self.entries[self.labelStrings[indexPath.row]]
			
		}
		self.navigationController?.pushViewController(self.folderVCs[indexPath.row]!, animated: true)
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}

	func loadData(){
		self.entries["Drafts"] = self.emailAcc!.draftFolder
		self.entries["Sent"] = self.emailAcc!.sentFolder
		self.entries["Deleted"] = self.emailAcc!.deletedFolder
		self.entries["Archive"] = self.emailAcc!.archiveFolder
		
		self.labelStrings.append("Drafts")
		self.labelStrings.append("Sent")
		self.labelStrings.append("Deleted")
		self.labelStrings.append("Archive")
	}
    
}
