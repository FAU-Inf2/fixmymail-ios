//
//  PreferenceAccountListTableViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 30.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import CoreData
import UIKit

class PreferenceAccountListTableViewController: UITableViewController {
	
	var delegate: ContentViewControllerProtocol?
	var navController: UINavigationController!
	var managedObjectContext: NSManagedObjectContext!
	var accountPreferenceCellItem: [ActionItem] = [ActionItem]()
	var otherItem: [ActionItem] = [ActionItem]()
	var sections = [String]()
	var rows = [AnyObject]()
        
    override func viewDidLoad() {
        super.viewDidLoad()
		
		loadCoreDataAccounts()
		
		
		tableView.registerNib(UINib(nibName: "PreferenceAccountListTableViewController", bundle: nil),forCellReuseIdentifier:"PreferenceCell")
		
		
		var menuItem: UIBarButtonItem = UIBarButtonItem(title: "   Menu", style: .Plain, target: self, action: "menuTapped:")
		self.navigationItem.title = "Accounts"
		self.navigationItem.leftBarButtonItem = menuItem
		
		self.sections = ["Accounts", "", ""]

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
		return self.sections.count
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.rows[section].count
	}
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return self.sections[section]
	}

	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PreferenceCell") as! PreferenceTableViewCell

        // Configure the cell...
		let cellItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
		cell.menuLabel.text = cellItem.cellName

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
	
	func loadCoreDataAccounts() {
		
		
	/*	var accountArr: [EmailAccount] = [EmailAccount]();
		let appDel: AppDelegate? = UIApplication.sharedApplication().delegate as? AppDelegate
		if let appDelegate = appDel {
			managedObjectContext = appDelegate.managedObjectContext
			var emailAccountsFetchRequest = NSFetchRequest(entityName: "EmailAccount")
			var error: NSError?
			let acc: [EmailAccount]? = managedObjectContext.executeFetchRequest(emailAccountsFetchRequest, error: &error) as? [EmailAccount]
			if let account = acc {
				for emailAcc: EmailAccount in account {
					accountArr.append(emailAcc)
				}
			} else {
				if((error) != nil) {
					NSLog(error!.description)
				}
			}
		}
		
		for emailAcc: EmailAccount in accountArr {
			var actionItem = ActionItem(Name: emailAcc.username, viewController: "PreferenceAccountView", mailAdress: emailAcc.emailAddress)
			accountPreferenceCellItem.append(actionItem)
		}

	*/
		var mailAccount = ActionItem(Name: "fixmaimaildummy", viewController: "Account_Detail", mailAdress: nil, icon: nil)
		accountPreferenceCellItem.append(mailAccount)
		
		
		var item1 = ActionItem(Name: "Add New Account", viewController: "CreateAccountView", mailAdress: nil, icon: nil)
		otherItem.append(ActionItem(Name: "Add New Account", viewController: "CreateAccountView", mailAdress: nil, icon: nil))
		
		rows.append(accountPreferenceCellItem)
		rows.append([])
		rows.append(otherItem)

	}
	
	@IBAction func menuTapped(sender: AnyObject) -> Void {
		self.delegate?.toggleLeftPanel()
	}
	
    
}
