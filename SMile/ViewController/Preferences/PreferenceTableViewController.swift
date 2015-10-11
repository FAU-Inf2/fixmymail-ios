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
	
	weak var delegate: ContentViewControllerProtocol?
	var navController: UINavigationController!
	var preferenceCellItem: [ActionItem] = [ActionItem]()
	var otherItem: [ActionItem] = [ActionItem]()
	var sections = [String]()
	var rows = [AnyObject]()
	
        
    override func viewDidLoad() {
        super.viewDidLoad()
		
		loadPreferenceCells()
		
		tableView.registerNib(UINib(nibName: "PreferenceTableViewCell", bundle: nil),forCellReuseIdentifier:"PreferenceCell")

		
		let menuItem: UIBarButtonItem = UIBarButtonItem(title: "   Menu", style: .Plain, target: self, action: "menuTapped:")
		self.navigationItem.title = "Preferences"
		self.navigationItem.leftBarButtonItem = menuItem
		
		self.sections = ["", "", "", ""]

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
	
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let fileName = (UIApplication.sharedApplication().delegate as! AppDelegate).fileName {
            if let data = (UIApplication.sharedApplication().delegate as! AppDelegate).fileData {
                let sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
                var sendAccount: EmailAccount? = nil
                
                let accountName = NSUserDefaults.standardUserDefaults().stringForKey("standardAccount")
                let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
                var error: NSError?
                var result: [AnyObject]?
                do {
                    result = try managedObjectContext.executeFetchRequest(fetchRequest)
                } catch let error1 as NSError {
                    error = error1
                    result = nil
                }
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
                    sendView.attachFile(fileName, data: data, mimetype: getPathExtensionFromString(fileName)!)
                    
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
		
		if cellItem.cellName == "Clear temporary files" {
			cell.menuLabel.textColor = UIColor.redColor()
		}
		
        return cell
    }
	
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let actionItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
		switch actionItem.cellName {
		case "Accounts":
			let prefAccountVC = PreferenceAccountListTableViewController(nibName: actionItem.viewController, bundle: nil)
			self.navigationController?.pushViewController(prefAccountVC, animated: true)
		case "Feedback":
			let feedbackVC = FeedbackViewController(nibName: actionItem.viewController, bundle: nil)
			self.navigationController?.pushViewController(feedbackVC, animated: true)
		case "About Us":
			let aboutUsVC = AboutUsViewController(nibName: actionItem.viewController, bundle: nil)
			self.navigationController?.pushViewController(aboutUsVC, animated: true)
		case "KeyChain":
			let prefKeyChainVC = PrefKeyChainTableViewController(nibName: actionItem.viewController, bundle: nil)
			self.navigationController?.pushViewController(prefKeyChainVC, animated: true)
		case "Clear temporary files":
			if self.deleteAllTempFiles() {
				let cell = self.tableView.cellForRowAtIndexPath(indexPath) as! PreferenceTableViewCell
				cell.menuLabel.textColor = UIColor.grayColor()
				cell.userInteractionEnabled = false
			}
		default:
			break
		}
		
		tableView.deselectRowAtIndexPath(indexPath, animated: true)

		
	}

	func loadPreferenceCells() {
		
		let item1 = ActionItem(Name: "Accounts", viewController: "PreferenceAccountListTableViewController", emailAddress: nil, icon: nil)
		let item2 = ActionItem(Name: "REMIND ME!", viewController: "TODO_Pref", emailAddress: nil, icon: nil)
		let item3 = ActionItem(Name: "KeyChain", viewController: "PrefKeyChainTableViewController", emailAddress: nil, icon: nil)
		let item4 = ActionItem(Name: "About Us", viewController: "AboutUsViewController", emailAddress: nil, icon: nil)
		let item5 = ActionItem(Name: "Feedback", viewController: "FeedbackViewController", emailAddress: nil, icon: nil)
		let item6 = ActionItem(Name: "Clear temporary files", viewController: "", emailAddress: nil, icon: nil)
		
		self.otherItem.append(item4)
		self.otherItem.append(item5)
		self.preferenceCellItem.append(item1)
		self.preferenceCellItem.append(item2)
		self.preferenceCellItem.append(item3)
		
		self.rows.append(preferenceCellItem)
		self.rows.append(otherItem)
		self.rows.append([])
		self.rows.append([item6])
		
	}
	
	func deleteAllTempFiles() -> Bool {
		let fileManager = NSFileManager.defaultManager()
		var documentDirectory = ""
		let nsDocumentDirectory = NSSearchPathDirectory.DocumentDirectory
		let nsUserDomainMask = NSSearchPathDomainMask.UserDomainMask
		let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
		if paths.count > 0 {
			documentDirectory = paths[0]
		}
		// contents of document directory
		var directoryContents: [String] = [String]()
		do {
			directoryContents = try fileManager.contentsOfDirectoryAtPath(documentDirectory)
		} catch _ {
			return false
		}
		
		for path in directoryContents {
			if path == "Inbox" {
				// contents of Inbox directory
				let inboxPath = (documentDirectory as NSString).stringByAppendingPathComponent(path)
				var inboxContents: [String] = [String]()
				do {
					inboxContents = try fileManager.contentsOfDirectoryAtPath(inboxPath)
				} catch _ {
					break
				}
				// delete files in Inbox directory
				for pathInInbox in inboxContents {
					let filePath = (inboxPath as NSString).stringByAppendingPathComponent(pathInInbox)
					do {
						try fileManager.removeItemAtPath(filePath)
					} catch _ {
					}
				}
				continue
			}
			
			// delete files in document directory
			if path.rangeOfString("SMile.sqlite") == nil {
				let filePath = (documentDirectory as NSString).stringByAppendingPathComponent(path)
				do {
					try fileManager.removeItemAtPath(filePath)
				} catch _ {
				}
			}
		}
		return true
	}
	
	@IBAction func menuTapped(sender: AnyObject) -> Void {
		self.delegate?.toggleLeftPanel()
	}
}
