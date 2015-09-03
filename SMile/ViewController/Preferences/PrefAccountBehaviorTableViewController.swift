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
	var folderLabelStrings = [String]()
	var optionsLabelStrings = [String]()
	var folderVCs:[PrefFolderSelectionTableViewController?] = [nil,nil,nil,nil]
	var downloadMailDurationVC: PrefDownloadMailDurationTableViewController?
	var sections = [String]()
	var rows = [AnyObject]()
        
    override func viewDidLoad() {
        super.viewDidLoad()
		
		loadData()

		tableView.registerNib(UINib(nibName: "PreferenceAccountTableViewCell", bundle: nil),forCellReuseIdentifier:"PreferenceAccountCell")
		self.navigationItem.title = "Account behavior"
		
		self.sections = ["Folders:", "Options:"]
		
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
	
	override func viewWillAppear(animated: Bool) {
		for var i = 0; i < self.folderVCs.count; i++ {
			if self.folderVCs[i] != nil {
				self.entries[self.folderLabelStrings[i]] = self.folderVCs[i]!.selectedFolderPath!
			}
		}
		
		if self.downloadMailDurationVC != nil {
			self.entries["Download mails for:"] = self.downloadMailDurationVC!.selectedString
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
        return self.sections.count
    }
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.rows[section].count
	}
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return self.sections[section]
	}

	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PreferenceAccountCell", forIndexPath: indexPath) as! PreferenceAccountTableViewCell
		// Configure the cell...
		cell.labelCellContent.text = self.rows[indexPath.section][indexPath.row] as? String
		cell.textfield.text = self.entries[(self.rows[indexPath.section][indexPath.row] as? String)!]
		if indexPath.section == 0 {
			cell.textfield.textAlignment = NSTextAlignment.Left
		} else {
			cell.textfield.textAlignment = NSTextAlignment.Right
		}
		
		cell.textfield.enabled = false
		cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator

        return cell
    }
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if indexPath.section == 0 {
			// folder selection
			if self.folderVCs[indexPath.row] == nil {
				self.folderVCs[indexPath.row] = PrefFolderSelectionTableViewController(nibName: "PrefFolderSelectionTableViewController", bundle: nil)
				self.folderVCs[indexPath.row]!.emailAcc = self.emailAcc!
				self.folderVCs[indexPath.row]!.StringForFolderBehavior = self.folderLabelStrings[indexPath.row]
				self.folderVCs[indexPath.row]!.selectedFolderPath = self.entries[self.folderLabelStrings[indexPath.row]]
				
			}
			self.navigationController?.pushViewController(self.folderVCs[indexPath.row]!, animated: true)
		} else {
			// download mail duration selection
			self.downloadMailDurationVC = PrefDownloadMailDurationTableViewController(nibName: "PrefDownloadMailDurationTableViewController", bundle: nil)
			self.downloadMailDurationVC!.selectedString = self.entries["Download mails for:"]!
			self.navigationController?.pushViewController(self.downloadMailDurationVC!, animated: true)
		}
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}

	func loadData(){
		self.entries["Drafts"] = self.emailAcc!.draftFolder
		self.entries["Sent"] = self.emailAcc!.sentFolder
		self.entries["Deleted"] = self.emailAcc!.deletedFolder
		self.entries["Archive"] = self.emailAcc!.archiveFolder
		
		self.folderLabelStrings.append("Drafts")
		self.folderLabelStrings.append("Sent")
		self.folderLabelStrings.append("Deleted")
		self.folderLabelStrings.append("Archive")
		
		self.entries["Download mails for:"] = self.emailAcc!.downloadMailDuration
		self.optionsLabelStrings.append("Download mails for:")
		
		self.rows.append(self.folderLabelStrings)
		self.rows.append(self.optionsLabelStrings)
		
	}
    
}
