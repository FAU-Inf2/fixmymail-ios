//
//  PreferenceTableViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 29.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class PreferenceTableViewController: UITableViewController {
	
	var delegate: ContentViewControllerProtocol?
	var navController: UINavigationController!
	var preferenceCellItem: [ActionItem] = [ActionItem]()
	var otherItem: [ActionItem] = [ActionItem]()
	var sections = [String]()
	var rows = [AnyObject]()
	
        
    override func viewDidLoad() {
        super.viewDidLoad()
		
		loadPreferenceCells()
		
		tableView.registerNib(UINib(nibName: "PreferenceTableViewCell", bundle: nil),forCellReuseIdentifier:"PreferenceCell")

		
		var menuItem: UIBarButtonItem = UIBarButtonItem(title: "   Menu", style: .Plain, target: self, action: "menuTapped:")
		self.navigationItem.title = "Preferences"
		self.navigationItem.leftBarButtonItem = menuItem
		
		self.sections = ["", "", ""]

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
        return self.sections.count
    }
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.rows[section].count
	}
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return self.sections[section]
	}

	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PreferenceCell", forIndexPath: indexPath) as! PreferenceTableViewCell

		
        // Configure the cell...
		let cellItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
		cell.menuLabel.text = cellItem.cellName
		
        return cell
    }
	
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let actionItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
		switch actionItem.cellName {
		case "Accounts":
			var prefAccountVC = PreferenceAccountListTableViewController(nibName:"PreferenceAccountListTableViewController", bundle: nil)
			self.navigationController?.pushViewController(prefAccountVC, animated: true)
		default:
			break
		}
		
		tableView.deselectRowAtIndexPath(indexPath, animated: true)

		
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
	
	func loadPreferenceCells() {
		
		var item1 = ActionItem(Name: "Accounts", viewController: "PreferenceAccountListTableViewController", emailAddress: nil, icon: nil)
		var item2 = ActionItem(Name: "TODO", viewController: "TODO_Pref", emailAddress: nil, icon: nil)
		var item3 = ActionItem(Name: "KeyChain", viewController: "KeyChain_Pref", emailAddress: nil, icon: nil)
		var item4 = ActionItem(Name: "About Us", viewController: "AboutUs", emailAddress: nil, icon: nil)
		var item5 = ActionItem(Name: "Feedback", viewController: "Feedback", emailAddress: nil, icon: nil)
		
		self.otherItem.append(item4)
		self.otherItem.append(item5)
		self.preferenceCellItem.append(item1)
		self.preferenceCellItem.append(item2)
		self.preferenceCellItem.append(item3)
		
		self.rows.append(preferenceCellItem)
		self.rows.append([])
		self.rows.append(otherItem)
		
	}
	
	@IBAction func menuTapped(sender: AnyObject) -> Void {
		self.delegate?.toggleLeftPanel()
	}
	
}
