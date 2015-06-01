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
	var accountArr: [EmailAccount] = [EmailAccount]();
	var otherArr: [EmailAccount] = [EmailAccount]();
	var accountPreferenceCellItem: [ActionItem] = [ActionItem]()
	var otherItem: [ActionItem] = [ActionItem]()
	var sections = [String]()
	var rows = [AnyObject]()
	var rowsEmail = [AnyObject]()
        
    override func viewDidLoad() {
        super.viewDidLoad()
		
		loadCoreDataAccounts()
		tableView.registerNib(UINib(nibName: "PreferenceTableViewCell", bundle: nil),forCellReuseIdentifier:"PreferenceCell")
		self.navigationItem.title = "Accounts"
		self.sections = ["Accounts", "", ""]

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(true)
		accountArr.removeAll(keepCapacity: false)
		otherArr.removeAll(keepCapacity: false)
		accountPreferenceCellItem.removeAll(keepCapacity: false)
		otherItem.removeAll(keepCapacity: false)
		rows.removeAll(keepCapacity: false)
		rowsEmail.removeAll(keepCapacity: false)
		
		loadCoreDataAccounts()
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
        let cell = tableView.dequeueReusableCellWithIdentifier("PreferenceCell", forIndexPath: indexPath) as! PreferenceTableViewCell

        // Configure the cell...
		let cellItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
		
		cell.menuLabel.text = cellItem.mailAdress
		cell.menuImg.image = cellItem.cellIcon
		
        return cell
    }
	
	
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		var editAccountVC = PreferenceEditAccountViewController(nibName:"PreferenceEditAccountViewController", bundle: nil)
		if let emailAccountItem = self.rowsEmail[indexPath.section][indexPath.row] as? EmailAccount {
			editAccountVC.emailAcc = emailAccountItem
		}
		var actionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
		editAccountVC.actionItem = actionItem
		
		self.navigationController?.pushViewController(editAccountVC, animated: true)
		
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		tableView.reloadData()
		
		
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
		
		
		// get mail accounts from coredata
		
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
		
		// create ActionItems for mail accounts
		for emailAcc: EmailAccount in accountArr {
			var accountImage: UIImage?
			
			// set icons
			switch emailAcc.emailAddress {
			case let s where s.rangeOfString("@gmail.com") != nil:
				accountImage = UIImage(named: "Gmail-128.png")
				
			case let s where s.rangeOfString("@outlook") != nil:
				accountImage = UIImage(named: "outlook.png")
				
			case let s where s.rangeOfString("@yahoo") != nil:
				accountImage = UIImage(named: "Yahoo-icon.png")
				
			case let s where s.rangeOfString("@web.de") != nil:
				accountImage = UIImage(named: "webde.png")
				
			case let s where s.rangeOfString("@gmx") != nil:
				accountImage = UIImage(named: "gmx.png")
				
			case let s where s.rangeOfString("@me.com") != nil:
				accountImage = UIImage(named: "icloud-icon.png")
				
			case let s where s.rangeOfString("@icloud.com") != nil:
				accountImage = UIImage(named: "icloud-icon.png")
				
			case let s where s.rangeOfString("@fau.de") != nil:
				accountImage = UIImage(named: "fau-logo.png")
				
			case let s where s.rangeOfString("@studium.fau.de") != nil:
				accountImage = UIImage(named: "fau-logo.png")

			default:
				accountImage = UIImage(named: "smile-gray.png")
				
			}
			
			
			var actionItem = ActionItem(Name: emailAcc.username, viewController: "PreferenceAccountView", mailAdress: emailAcc.emailAddress, icon: accountImage)
			accountPreferenceCellItem.append(actionItem)
		}

		// Add New Account Cell
		otherItem.append(ActionItem(Name: "Add New Account", viewController: "CreateAccountView", mailAdress: "Add New Account", icon: UIImage(named: "ios7-plus.png")))
		
		
		rows.append(accountPreferenceCellItem)
		rows.append([])
		rows.append(otherItem)
		
		rowsEmail.append(accountArr)
		rowsEmail.append([])
		rowsEmail.append(otherItem)

	}
	
	@IBAction func menuTapped(sender: AnyObject) -> Void {
		self.delegate?.toggleLeftPanel()
	}
	
    
}
