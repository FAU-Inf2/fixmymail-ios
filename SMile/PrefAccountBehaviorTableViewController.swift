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
        return self.entries.count
    }

	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PreferenceAccountCell", forIndexPath: indexPath) as! PreferenceAccountTableViewCell
		
		cell.labelCellContent.text = self.labelStrings[indexPath.row]
		cell.textfield.text = self.entries[self.labelStrings[indexPath.row]]
		cell.textfield.textAlignment = NSTextAlignment.Right
		cell.textfield.enabled = false
		cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
		

        // Configure the cell...

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
