//
//  PreferenceTableViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 29.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import CoreData

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
	
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let fileName = (UIApplication.sharedApplication().delegate as! AppDelegate).fileName {
            if let data = (UIApplication.sharedApplication().delegate as! AppDelegate).fileData {
                var sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
                var sendAccount: EmailAccount? = nil
                
                var accountName = NSUserDefaults.standardUserDefaults().stringForKey("standardAccount")
                let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
                var error: NSError?
                var result = managedObjectContext.executeFetchRequest(fetchRequest, error: &error)
                if error != nil {
                    NSLog("%@", error!.description)
                    return
                } else {
                    if let emailAccounts = result {
                        for account in emailAccounts {
                            if (account as! EmailAccount).accountName == accountName {
                                sendAccount = account as? EmailAccount
                                break
                            }
                        }
                        if sendAccount == nil {
                            sendAccount = emailAccounts.first as? EmailAccount
                        }
                    }
                }
                
                if let account = sendAccount {
                    sendView.account = account
                    sendView.attachFile(fileName, data: data, mimetype: fileName.pathExtension)
                    
                    (UIApplication.sharedApplication().delegate as! AppDelegate).fileName = nil
                    (UIApplication.sharedApplication().delegate as! AppDelegate).fileData = nil
                    
                    self.navigationController?.pushViewController(sendView, animated: true)
                }
            }
        }
        
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
		cell.menuLabel.text = cellItem.cellName
		
        return cell
    }
	
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let actionItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
		switch actionItem.cellName {
		case "Accounts":
			var prefAccountVC = PreferenceAccountListTableViewController(nibName: actionItem.viewController, bundle: nil)
			self.navigationController?.pushViewController(prefAccountVC, animated: true)
		case "Feedback":
			var feedbackVC = FeedbackViewController(nibName: actionItem.viewController, bundle: nil)
			self.navigationController?.pushViewController(feedbackVC, animated: true)
		case "About Us":
			var aboutUsVC = AboutUsViewController(nibName: actionItem.viewController, bundle: nil)
			self.navigationController?.pushViewController(aboutUsVC, animated: true)
		default:
			break
		}
		
		tableView.deselectRowAtIndexPath(indexPath, animated: true)

		
	}

	func loadPreferenceCells() {
		
		var item1 = ActionItem(Name: "Accounts", viewController: "PreferenceAccountListTableViewController", emailAddress: nil, icon: nil)
		var item2 = ActionItem(Name: "REMIND ME!", viewController: "TODO_Pref", emailAddress: nil, icon: nil)
		var item3 = ActionItem(Name: "KeyChain", viewController: "KeyChain_Pref", emailAddress: nil, icon: nil)
		var item4 = ActionItem(Name: "About Us", viewController: "AboutUsViewController", emailAddress: nil, icon: nil)
		var item5 = ActionItem(Name: "Feedback", viewController: "FeedbackViewController", emailAddress: nil, icon: nil)
		
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
